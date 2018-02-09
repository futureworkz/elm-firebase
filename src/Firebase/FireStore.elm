{--
TODO
* Allow cancellation of subscription
* Add queries to collection
* Auth
* Storage
* Write docs/README
* Normalise path eg. /path//with//double/or/ending/

Caveats:
* State stores all subscriptions based on the Path as key.
This means that user cannot subscribe to the same path with different queries.
Design choice is made because we cannot differentiate between subscriptions other than Path.

* All snapshot's data is sent back as JSON.
This means user will have to decode their data.
Design choice is made because our State cannot hold different types of subscription data
and sending as JSON means that we enforce user to decode and maintain type safety.
--}


effect module Firebase.FireStore
    where { subscription = CreateSubMsg }
    exposing
        ( onDocSnapshot
        , onCollectionSnapshot
        , doc
        , collection
        , add
        , where_
        , orderBy
        , limit
        , isAdded
        , isModified
        , isRemoved
        , asc
        , desc
        , gt
        , gte
        , eq
        , lt
        , lte
        , listOf
        , string
        , date
        , number_
        , customValue
        , bool
        , docID
        , path
        , serverTimestamp
        , DocumentSnapshot
        , QuerySnapshot
        , DocumentChange
        , ListOf
        , Path
        , FieldPath
        , Json
        )

import Array
import Date
import Task exposing (Task)
import Native.FireStore


type alias DocumentSnapshot =
    { id : String
    , data : Json
    }


type alias QuerySnapshot =
    { changes : List DocumentChange
    , docs : List DocumentSnapshot
    }


type alias DocumentChange =
    { doc : DocumentSnapshot
    , type_ : DocumentChangeType
    }


type alias FieldPath =
    String


type alias Json =
    String



-- Opaque types


type CreateSubMsg msg
    = OnDocSnapshot PathString (DocumentSnapshot -> msg)
    | OnQuerySnapshot PathString (List Query) (QuerySnapshot -> msg)


type Msg msg
    = NewDocSnapshot (DocumentSnapshot -> msg) DocumentSnapshot
    | NewCollectionSnapshot (QuerySnapshot -> msg) QuerySnapshot


type alias State =
    List PathString


type Doc schema dataType
    = Doc (Path schema dataType)


type Collection schema dataType
    = Collection (List Query) (Path schema (ListOf dataType))


type Path schema dataType
    = Path schema (schema -> dataType) PathString


type alias PathString =
    String


type ListOf a
    = ListOf String a


type DocumentChangeType
    = Added
    | Modified
    | Removed


type Query
    = Where FieldPath Op String
    | Limit Int
    | OrderBy FieldPath Direction


type Direction
    = Asc
    | Desc


type Op
    = Gt
    | Gte
    | Eq
    | Lt
    | Lte



-- Schema helpers


listOf : String -> a -> ListOf a
listOf idDescription a =
    ListOf idDescription a


path : schema -> (schema -> dataType) -> Path schema dataType
path schema fields =
    Path schema fields <|
        Native.FireStore.pathString fields


docID : String -> ListOf a -> a
docID id collection =
    case collection of
        ListOf _ a ->
            a


serverTimestamp : Date.Date
serverTimestamp =
    Date.fromTime 0


string : String
string =
    "String"


date : Date.Date
date =
    Date.fromTime 0


number_ : number
number_ =
    1


bool : Bool
bool =
    True


customValue : a -> a
customValue a =
    a



-- Query helpers


doc : Path schema dataType -> Doc schema dataType
doc path =
    Doc path


collection : Path schema (ListOf dataType) -> Collection schema dataType
collection path =
    Collection [] path


add : dataType -> Collection schema dataType -> Task Never Doc
add data collection =
    case collection of
        Collection _ path ->
            getPathString path
                |> Native.FireStore.add data


where_ : FieldPath -> Op -> String -> Collection schema dataType -> Collection schema dataType
where_ fieldPath op value ref =
    case ref of
        Collection queries path ->
            Collection (queries ++ [ Where fieldPath op value ]) path


orderBy : FieldPath -> Direction -> Collection schema dataType -> Collection schema dataType
orderBy fieldPath direction ref =
    case ref of
        Collection queries path ->
            Collection (queries ++ [ OrderBy fieldPath direction ]) path


limit : Int -> Collection schema dataType -> Collection schema dataType
limit num ref =
    case ref of
        Collection queries path ->
            Collection (queries ++ [ Limit num ]) path


isAdded : DocumentChangeType -> Bool
isAdded changeType =
    case changeType of
        Added ->
            True

        _ ->
            False


isModified : DocumentChangeType -> Bool
isModified changeType =
    case changeType of
        Modified ->
            True

        _ ->
            False


isRemoved : DocumentChangeType -> Bool
isRemoved changeType =
    case changeType of
        Removed ->
            True

        _ ->
            False


asc : Direction
asc =
    Asc


desc : Direction
desc =
    Desc


gt : Op
gt =
    Gt


gte : Op
gte =
    Gte


eq : Op
eq =
    Eq


lt : Op
lt =
    Lt


lte : Op
lte =
    Lte



-- Create Subscriptions


onDocSnapshot : (DocumentSnapshot -> msg) -> Doc schema dataType -> Sub msg
onDocSnapshot tagger doc =
    case doc of
        Doc path ->
            subscription (OnDocSnapshot (getPathString path) tagger)


onCollectionSnapshot : (QuerySnapshot -> msg) -> Collection schema dataType -> Sub msg
onCollectionSnapshot tagger collection =
    case collection of
        Collection queries path ->
            subscription (OnQuerySnapshot (getPathString path) queries tagger)



{--
The code below are standard wiring required by effect manager.
For effect manager to work, we need to tell it
* a type (CreateSubMsg) to send when user wants to subscribe to something
* a type (Msg) for internal usage with our own functions
* a type (State) to hold all the information of our subscriptions

Effect manager also requires the following functions to be defined:
* init
* subMap
* onEffects
* onSelfMsg
--}


init : Task Never State
init =
    Task.succeed []


subMap : (a -> b) -> CreateSubMsg a -> CreateSubMsg b
subMap func sub =
    case sub of
        OnDocSnapshot pathString tagger ->
            OnDocSnapshot pathString (tagger >> func)

        OnQuerySnapshot pathString queries tagger ->
            OnQuerySnapshot pathString queries (tagger >> func)


onEffects : Platform.Router msg (Msg msg) -> List (CreateSubMsg msg) -> State -> Task Never State
onEffects router subs state =
    removeSubs subs state
        |> addNewSubs router subs
        |> Task.succeed


onSelfMsg : Platform.Router msg (Msg msg) -> Msg msg -> State -> Task Never State
onSelfMsg router msg state =
    case msg of
        NewDocSnapshot tagger snapshot ->
            Platform.sendToApp router (tagger snapshot)
                |> Task.andThen (always (Task.succeed state))

        NewCollectionSnapshot tagger snapshot ->
            Platform.sendToApp router (tagger snapshot)
                |> Task.andThen (always (Task.succeed state))


removeSubs : List (CreateSubMsg msg) -> State -> State
removeSubs subs state =
    let
        subPaths =
            List.map
                (\sub ->
                    case sub of
                        OnDocSnapshot pathString _ ->
                            pathString

                        OnQuerySnapshot pathString _ _ ->
                            pathString
                )
                subs

        isInSubPaths =
            \path -> List.member path subPaths

        ( newState, removedPaths ) =
            List.partition isInSubPaths state
    in
        List.map Native.FireStore.removeListener removedPaths
            |> always newState


addNewSubs : Platform.Router msg (Msg msg) -> List (CreateSubMsg msg) -> State -> State
addNewSubs router subs state =
    case subs of
        sub :: rest ->
            let
                subPath =
                    getPathFromCreateSubMsg sub
            in
                case List.member subPath state of
                    True ->
                        addNewSubs router rest state

                    False ->
                        createSub router sub state
                            |> addNewSubs router rest

        [] ->
            state


createSub : Platform.Router msg (Msg msg) -> CreateSubMsg msg -> State -> State
createSub router sub state =
    let
        subPath =
            getPathFromCreateSubMsg sub

        subPathIsInState =
            List.member subPath state
    in
        if subPathIsInState then
            state
        else
            let
                newState =
                    subPath :: state
            in
                case sub of
                    OnDocSnapshot pathString tagger ->
                        sendNewDocSnapshot router tagger
                            |> Native.FireStore.onDocSnapshot pathString
                            |> always newState

                    OnQuerySnapshot pathString queries tagger ->
                        sendNewCollectionSnapshot router tagger
                            |> Native.FireStore.onCollectionSnapshot (Array.fromList queries) pathString
                            |> always newState


sendNewDocSnapshot :
    Platform.Router msg (Msg msg)
    -> (DocumentSnapshot -> msg)
    -> placeHolderForNativeModuleA2
    -> DocumentSnapshot
    -> Platform.Task x ()
sendNewDocSnapshot router tagger _ snapshot =
    Platform.sendToSelf router (NewDocSnapshot tagger snapshot)


sendNewCollectionSnapshot :
    Platform.Router msg (Msg msg)
    -> (QuerySnapshot -> msg)
    -> placeHolderForNativeModuleA2
    -> QuerySnapshot
    -> Platform.Task x ()
sendNewCollectionSnapshot router tagger _ snapshot =
    Platform.sendToSelf router (NewCollectionSnapshot tagger snapshot)


getPathFromCreateSubMsg : CreateSubMsg msg -> PathString
getPathFromCreateSubMsg msg =
    case msg of
        OnDocSnapshot pathString _ ->
            pathString

        OnQuerySnapshot pathString _ _ ->
            pathString


getPathString : Path schema fields -> PathString
getPathString path =
    case path of
        Path _ _ path ->
            path
