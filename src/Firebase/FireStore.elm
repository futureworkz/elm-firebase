{--
TODO
* Finish all queries to collection
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

* db.doc.update() does not support multipath update because FireStore does not have multipath update anymore (use batch)
It is actually more like set() becase it does not allows partial updating of a record
though user can workaround it by passing a limited encoder
--}


effect module Firebase.FireStore
    where { subscription = CreateSubMsg }
    exposing
        ( onDocSnapshot
        , onCollectionSnapshot
        , onCollectionSnapshotWithOptions
        , doc
        , set
        , get
        , getCollection
        , update
        , delete
        , batch
        , batchSet
        , batchUpdate
        , batchDelete
        , collection
        , add
        , where_
        , whereBool
        , whereDate
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
        , arrayContains
        , listOf
        , listString
        , listObject
        , string
        , date
        , timestamp
        , number_
        , customValue
        , bool
        , docID
        , path
        , encodedServerTimeStamp
        , encodeDate
        , generateID
        , Collection
        , Doc
        , DocumentSnapshot
        , QuerySnapshot
        , QueryListenOptions
        , DocumentChange
        , Error(Error)
        , ErrorCode(..)
        , ListOf
        , Path
        , FieldPath
        , Json
        , ObjectEncoder
        , DocID
        )

import Array
import Date exposing (Date)
import Time exposing (Time)
import Task exposing (Task)
import Native.FireStore
import Json.Encode as JE


type alias DocumentSnapshot =
    { id : String
    , data : Json
    , metadata : DocumentMetadata
    }


type alias DocumentMetadata =
    { fromCache : Bool
    , hasPendingWrites : Bool
    }


type alias QuerySnapshot =
    { changes : List DocumentChange
    , docs : List DocumentSnapshot
    }


type alias QueryListenOptions =
    { includeMetadataChanges : Bool
    }


type alias DocumentChange =
    { doc : DocumentSnapshot
    , type_ : DocumentChangeType
    }


type alias FieldPath =
    String


type alias Json =
    String


type alias DocID =
    String


type alias ObjectEncoder dataType =
    -- TODO: Should ObjectEncoder be ObjectEncoder data snapshot?
    List ( String, dataType -> JE.Value )


type Error
    = Error ErrorCode String


type ErrorCode
    = Cancelled
    | Unknown
    | InvalidArgument
    | DeadlineExceeded
    | NotFound
    | AlreadyExists
    | PermissionDenied
    | ResourceExhausted
    | FailedPrecondition
    | Aborted
    | OutOfRange
    | Unimplemented
    | Internal
    | Unavailable
    | DataLoss
    | Unauthenticated
    | UndocumentedErrorByElmFirebase
    | DocumentNotFound



-- Opaque types


type CreateSubMsg msg
    = OnDocSnapshot PathString (DocumentSnapshot -> msg)
    | OnQuerySnapshot PathString (List Query) (QuerySnapshot -> msg)
    | OnQuerySnapshotWithOptions PathString (List Query) (QuerySnapshot -> msg) QueryListenOptions


type Msg msg
    = NewDocSnapshot (DocumentSnapshot -> msg) DocumentSnapshot
    | NewCollectionSnapshot (QuerySnapshot -> msg) QuerySnapshot


type alias State =
    List PathString


type Doc schema dataType
    = Doc (Path schema dataType)


type WriteBatch
    = BatchSet Json PathString
    | BatchUpdate Json PathString
    | BatchDelete PathString


type Collection schema dataType
    = Collection (List Query) (Path schema (ListOf dataType))


type Path schema dataType
    = Path schema (schema -> dataType) PathString


type alias PathString =
    String


type alias ListenerID =
    String


type ListOf a
    = ListOf String a


type DocumentChangeType
    = Added
    | Modified
    | Removed


type Query
    = Where FieldPath Op String
    | WhereDate FieldPath Op Date
    | WhereBool FieldPath Op Bool
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
    | ArrayContains



-- Schema helpers


listOf : String -> a -> ListOf a
listOf idDescription a =
    ListOf idDescription a


path : schema -> (schema -> dataType) -> Path schema dataType
path schema fields =
    Path schema fields <| Native.FireStore.pathString fields


docID : String -> ListOf a -> a
docID _ (ListOf _ a) =
    a


encodedServerTimeStamp : a -> JE.Value
encodedServerTimeStamp _ =
    JE.string "ELM-FIREBASE::ENCODED-SERVER-TIME-STAMP"


encodeDate : Date -> JE.Value
encodeDate date =
    let
        format int =
            String.padLeft 2 '0' (toString int)
    in
        JE.string <|
            "ELM-FIREBASE::ENCODED-DATE|"
                ++ (toString <| Date.toTime date)


string : String
string =
    "String"


listString : List String
listString =
    []


listObject : a -> List a
listObject a =
    []


date : Date.Date
date =
    Date.fromTime 0


timestamp : Time
timestamp =
    Date.toTime <| Date.fromTime 0


number_ : number
number_ =
    1


bool : Bool
bool =
    True


customValue : a -> a
customValue a =
    a



-- Document functions


doc : Path schema dataType -> Doc schema dataType
doc path =
    Doc path


get : Doc schema dataType -> Task Error DocumentSnapshot
get doc =
    Native.FireStore.get <| getDocPathString doc


set : ObjectEncoder dataType -> dataType -> Doc schema dataType -> Task Error ()
set objEncoder data doc =
    Native.FireStore.set (encodeToJson objEncoder data) <| getDocPathString doc


update : ObjectEncoder dataType -> dataType -> Doc schema dataType -> Task Error ()
update objEncoder data doc =
    Native.FireStore.update (encodeToJson objEncoder data) <| getDocPathString doc


delete : Doc schema dataType -> Task Error ()
delete doc =
    Native.FireStore.delete_ <| getDocPathString doc


batch : List WriteBatch -> Task Error ()
batch operations =
    let
        toObject operation =
            case operation of
                BatchSet json path ->
                    { ops = "Set", json = json, path = path }

                BatchUpdate json path ->
                    { ops = "Update", json = json, path = path }

                BatchDelete path ->
                    { ops = "Delete", json = "", path = path }
    in
        List.map toObject operations
            |> Array.fromList
            |> Native.FireStore.batchAndCommit


batchSet : ObjectEncoder dataType -> dataType -> Doc schema dataType -> WriteBatch
batchSet objEncoder data doc =
    BatchSet (encodeToJson objEncoder data) <| getDocPathString doc


batchUpdate : ObjectEncoder dataType -> dataType -> Doc schema dataType -> WriteBatch
batchUpdate objEncoder data doc =
    BatchUpdate (encodeToJson objEncoder data) <| getDocPathString doc


batchDelete : ObjectEncoder dataType -> dataType -> Doc schema dataType -> WriteBatch
batchDelete objEncoder data doc =
    BatchDelete <| getDocPathString doc



-- Collection functions


collection : Path schema (ListOf dataType) -> Collection schema dataType
collection path =
    Collection [] path


getCollection : Collection schema dataType -> Task Error (List DocumentSnapshot)
getCollection (Collection queries path) =
    let
        queryArray =
            (Array.fromList queries)

        pathString =
            getPathString path
    in
        Native.FireStore.getCollection queryArray pathString



--TODO: Add function should return a Doc instead of DocID


add : ObjectEncoder dataType -> dataType -> Collection schema dataType -> Task Error DocID
add objEncoder data collection =
    Native.FireStore.add (encodeToJson objEncoder data) <| getCollectionPathString collection


where_ : FieldPath -> Op -> String -> Collection schema dataType -> Collection schema dataType
where_ fieldPath op value (Collection queries path) =
    Collection (queries ++ [ Where fieldPath op value ]) path


whereDate : FieldPath -> Op -> Date -> Collection schema dataType -> Collection schema dataType
whereDate fieldPath op value (Collection queries path) =
    Collection (queries ++ [ WhereDate fieldPath op value ]) path


whereBool : FieldPath -> Op -> Bool -> Collection schema dataType -> Collection schema dataType
whereBool fieldPath op value (Collection queries path) =
    Collection (queries ++ [ WhereBool fieldPath op value ]) path


orderBy : FieldPath -> Direction -> Collection schema dataType -> Collection schema dataType
orderBy fieldPath direction (Collection queries path) =
    Collection (queries ++ [ OrderBy fieldPath direction ]) path


limit : Int -> Collection schema dataType -> Collection schema dataType
limit num (Collection queries path) =
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


arrayContains : Op
arrayContains =
    ArrayContains


generateID : Task x String
generateID =
    Native.FireStore.generateID ()



-- Create Subscriptions


onDocSnapshot : (DocumentSnapshot -> msg) -> Doc schema dataType -> Sub msg
onDocSnapshot tagger (Doc path) =
    subscription <| OnDocSnapshot (getPathString path) tagger


onCollectionSnapshot : (QuerySnapshot -> msg) -> Collection schema dataType -> Sub msg
onCollectionSnapshot tagger (Collection queries path) =
    subscription <| OnQuerySnapshot (getPathString path) queries tagger


onCollectionSnapshotWithOptions : (QuerySnapshot -> msg) -> QueryListenOptions -> Collection schema dataType -> Sub msg
onCollectionSnapshotWithOptions tagger options (Collection queries path) =
    subscription <| OnQuerySnapshotWithOptions (getPathString path) queries tagger options



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

        OnQuerySnapshotWithOptions pathString queries tagger options ->
            OnQuerySnapshotWithOptions pathString queries (tagger >> func) options


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
        listenerIDs =
            List.map createListenerID subs

        isAlreadySubscribed =
            \listenerID -> List.member listenerID listenerIDs

        ( newState, removedListeners ) =
            List.partition isAlreadySubscribed state
    in
        List.map Native.FireStore.removeListener removedListeners
            |> always newState


addNewSubs : Platform.Router msg (Msg msg) -> List (CreateSubMsg msg) -> State -> State
addNewSubs router subs state =
    case subs of
        sub :: rest ->
            let
                listenerID =
                    createListenerID sub
            in
                case List.member listenerID state of
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
        listenerID =
            createListenerID sub

        subIsAlreadySubscribed =
            List.member listenerID state
    in
        if subIsAlreadySubscribed then
            state
        else
            let
                newState =
                    listenerID :: state
            in
                case sub of
                    OnDocSnapshot pathString tagger ->
                        sendNewDocSnapshot router tagger
                            |> Native.FireStore.onDocSnapshot listenerID pathString
                            |> always newState

                    OnQuerySnapshot pathString queries tagger ->
                        sendNewCollectionSnapshot router tagger
                            |> Native.FireStore.onCollectionSnapshot listenerID (Array.fromList queries) pathString
                            |> always newState

                    OnQuerySnapshotWithOptions pathString queries tagger options ->
                        sendNewCollectionSnapshot router tagger
                            |> Native.FireStore.onCollectionSnapshotWithOptions listenerID (Array.fromList queries) options pathString
                            |> always newState


createListenerID : CreateSubMsg msg -> ListenerID
createListenerID subMsg =
    case subMsg of
        OnDocSnapshot pathString _ ->
            pathString

        OnQuerySnapshot pathString queries _ ->
            pathString ++ (String.join "" <| List.map serializeQuery queries)

        OnQuerySnapshotWithOptions pathString queries _ _ ->
            pathString ++ (String.join "" <| List.map serializeQuery queries)


serializeQuery : Query -> String
serializeQuery query =
    case query of
        Where field op value ->
            "W" ++ field ++ toString op ++ value

        WhereDate field op date ->
            "D" ++ field ++ toString op ++ toString (Date.toTime date)

        WhereBool field op bool ->
            "B" ++ field ++ toString op ++ toString bool

        Limit limit ->
            "L" ++ toString limit

        OrderBy field direction ->
            "O" ++ field ++ toString direction


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



--- Helpers


encodeToJson : ObjectEncoder dataType -> dataType -> String
encodeToJson objectEncoder data =
    objectEncoder
        |> List.map (applyFieldEncoder data)
        |> JE.object
        |> JE.encode 0


applyFieldEncoder : dataType -> ( String, dataType -> JE.Value ) -> ( String, JE.Value )
applyFieldEncoder data ( fieldName, encoder ) =
    ( fieldName, encoder data )


getPathFromCreateSubMsg : CreateSubMsg msg -> PathString
getPathFromCreateSubMsg msg =
    case msg of
        OnDocSnapshot pathString _ ->
            pathString

        OnQuerySnapshot pathString _ _ ->
            pathString

        OnQuerySnapshotWithOptions pathString _ _ _ ->
            pathString


getDocPathString : Doc schema dataType -> PathString
getDocPathString (Doc path) =
    getPathString path


getCollectionPathString : Collection schema dataType -> PathString
getCollectionPathString (Collection _ path) =
    getPathString path


getPathString : Path schema fields -> PathString
getPathString (Path _ _ path) =
    path
