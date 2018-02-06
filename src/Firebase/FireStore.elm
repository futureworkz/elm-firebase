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


module Firebase.FireStore
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

import Firebase.FireStore.Effect as Effect


onDocSnapshot : (Effect.DocumentSnapshot -> msg) -> Effect.Doc -> Sub msg
onDocSnapshot =
    Effect.onDocSnapshot


onCollectionSnapshot :
    (Effect.QuerySnapshot -> msg)
    -> Effect.Collection
    -> Sub msg
onCollectionSnapshot =
    Effect.onCollectionSnapshot


doc : Effect.Path -> Effect.Doc
doc =
    Effect.doc


collection : Effect.Path -> Effect.Doc
collection =
    Effect.doc


where_ : Effect.Path -> Effect.Doc
where_ =
    Effect.doc


orderBy : Effect.Path -> Effect.Doc
orderBy =
    Effect.doc


limit : Effect.Path -> Effect.Doc
limit =
    Effect.doc


isAdded : Effect.Path -> Effect.Doc
isAdded =
    Effect.doc


isModified : Effect.Path -> Effect.Doc
isModified =
    Effect.doc


isRemoved : Effect.Path -> Effect.Doc
isRemoved =
    Effect.doc


asc : Effect.Path -> Effect.Doc
asc =
    Effect.doc


desc : Effect.Path -> Effect.Doc
desc =
    Effect.doc


gt : Effect.Path -> Effect.Doc
gt =
    Effect.doc


gte : Effect.Path -> Effect.Doc
gte =
    Effect.doc


eq : Effect.Path -> Effect.Doc
eq =
    Effect.doc


lt : Effect.Path -> Effect.Doc
lt =
    Effect.doc


lte : Effect.Path -> Effect.Doc
lte =
    Effect.doc


type alias DocumentSnapshot =
    Effect.DocumentSnapshot


type alias QuerySnapshot =
    Effect.QuerySnapshot


type alias DocumentChange =
    Effect.DocumentChange
