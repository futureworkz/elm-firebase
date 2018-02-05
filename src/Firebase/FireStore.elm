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

import Dict exposing (Dict)
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



-- TODO: Cancel Subscriptions
-- Managing effects


type CreateSubMsg msg
    = OnDocSnapshot Doc (DocumentSnapshot -> msg)
    | OnQuerySnapshot Collection (QuerySnapshot -> msg)


type Msg msg
    = NewDocSnapshot (DocumentSnapshot -> msg) DocumentSnapshot
    | NewCollectionSnapshot (QuerySnapshot -> msg) QuerySnapshot


type alias State msg =
    Dict Path (CreateSubMsg msg)


init : Task Never (State msg)
init =
    Task.succeed Dict.empty


subMap : (a -> b) -> CreateSubMsg a -> CreateSubMsg b
subMap func sub =
    case sub of
        OnDocSnapshot ref tagger ->
            OnDocSnapshot ref (tagger >> func)

        OnQuerySnapshot ref tagger ->
            OnQuerySnapshot ref (tagger >> func)


onEffects : Platform.Router msg (Msg msg) -> List (CreateSubMsg msg) -> State msg -> Task Never (State msg)
onEffects router subs state =
    case subs of
        sub :: rest ->
            createSub router sub state
                |> Task.andThen (onEffects router rest)

        [] ->
            Task.succeed state


createSub : Platform.Router msg (Msg msg) -> CreateSubMsg msg -> State msg -> Task Never (State msg)
createSub router sub state =
    case sub of
        OnDocSnapshot (Doc path) tagger ->
            case Dict.get path state of
                Just _ ->
                    Task.succeed state

                Nothing ->
                    let
                        listener =
                            \_ snapshot ->
                                Platform.sendToSelf router (NewDocSnapshot tagger snapshot)

                        newState =
                            Dict.insert path sub state
                    in
                        Native.Firebase.onDocSnapshot path listener
                            |> always (Task.succeed newState)

        OnQuerySnapshot (Collection queries path) tagger ->
            case Dict.get path state of
                Just _ ->
                    Task.succeed state

                Nothing ->
                    let
                        listener =
                            \_ snapshot -> Platform.sendToSelf router (NewCollectionSnapshot tagger snapshot)

                        newState =
                            Dict.insert path sub state
                    in
                        Native.Firebase.onCollectionSnapshot queries path listener
                            |> always (Task.succeed newState)


onSelfMsg : Platform.Router msg (Msg msg) -> Msg msg -> State msg -> Task Never (State msg)
onSelfMsg router msg state =
    case msg of
        NewDocSnapshot tagger snapshot ->
            Platform.sendToApp router (tagger snapshot)
                |> Task.andThen (always (Task.succeed state))

        NewCollectionSnapshot tagger snapshot ->
            Platform.sendToApp router (tagger snapshot)
                |> Task.andThen (always (Task.succeed state))
