{--
TODO
* Allow cancellation of subscription
* Add queries to collection
* Auth
* Storage
* Write docs/README

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
        , DocumentSnapshot
        , QuerySnapshot
        , DocumentChange
        )

import Array
import Task exposing (Task)


type alias DocumentSnapshot =
    { id : String
    , data : JsonString
    }


type alias QuerySnapshot =
    { changes : List DocumentChange
    , docs : List DocumentSnapshot
    }


type alias DocumentChange =
    { doc : DocumentSnapshot
    , type_ : DocumentChangeType
    }


type alias Path =
    String


type alias FieldPath =
    String


type alias JsonString =
    String



-- Opaque types


type CreateSubMsg msg
    = OnDocSnapshot Doc (DocumentSnapshot -> msg)
    | OnQuerySnapshot Collection (QuerySnapshot -> msg)


type Msg msg
    = NewDocSnapshot (DocumentSnapshot -> msg) DocumentSnapshot
    | NewCollectionSnapshot (QuerySnapshot -> msg) QuerySnapshot


type alias State =
    List Path


type Collection
    = Collection (List Query) Path


type Doc
    = Doc Path


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


doc : Path -> Doc
doc path =
    Doc path


collection : Path -> Collection
collection path =
    Collection [] path


where_ : FieldPath -> Op -> String -> Collection -> Collection
where_ fieldPath op value ref =
    case ref of
        Collection queries path ->
            Collection (queries ++ [ Where fieldPath op value ]) path


orderBy : FieldPath -> Direction -> Collection -> Collection
orderBy fieldPath direction ref =
    case ref of
        Collection queries path ->
            Collection (queries ++ [ OrderBy fieldPath direction ]) path


limit : Int -> Collection -> Collection
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


onDocSnapshot : (DocumentSnapshot -> msg) -> Doc -> Sub msg
onDocSnapshot tagger ref =
    subscription (OnDocSnapshot ref tagger)


onCollectionSnapshot : (QuerySnapshot -> msg) -> Collection -> Sub msg
onCollectionSnapshot tagger ref =
    subscription (OnQuerySnapshot ref tagger)



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
        OnDocSnapshot ref tagger ->
            OnDocSnapshot ref (tagger >> func)

        OnQuerySnapshot ref tagger ->
            OnQuerySnapshot ref (tagger >> func)


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
                        OnDocSnapshot (Doc path) _ ->
                            path

                        OnQuerySnapshot (Collection _ path) _ ->
                            path
                )
                subs

        isInSubPaths =
            \path -> List.member path subPaths

        ( newState, removedPaths ) =
            List.partition isInSubPaths state
    in
        List.map Native.Firebase.removeListeners removedPaths
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
                    OnDocSnapshot (Doc path) tagger ->
                        sendNewDocSnapshot router tagger
                            |> Native.Firebase.onDocSnapshot path
                            |> always newState

                    OnQuerySnapshot (Collection queries path) tagger ->
                        sendNewCollectionSnapshot router tagger
                            |> Native.Firebase.onCollectionSnapshot (Array.fromList queries) path
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


getPathFromCreateSubMsg : CreateSubMsg msg -> Path
getPathFromCreateSubMsg msg =
    case msg of
        OnDocSnapshot (Doc path) _ ->
            path

        OnQuerySnapshot (Collection _ path) _ ->
            path
