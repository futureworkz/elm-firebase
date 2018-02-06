module Tests.Firebase.FireStore exposing (..)

import Test exposing (..)
import Expect exposing (..)
import Native.Firebase
import Firebase.FireStore.Effect exposing (..)


docOne : CreateSubMsg DocumentSnapshot
docOne =
    OnDocSnapshot (Doc "/one/one") identity


collectionOne : CreateSubMsg QuerySnapshot
collectionOne =
    OnQuerySnapshot (Collection [] "/one") identity


suite : Test
suite =
    describe "#FireStore.Effect"
        [ test "removeSubs" <|
            \_ ->
                let
                    state =
                        [ "/one/one"
                        , "/one"
                        ]

                    subs =
                        []
                in
                    removeSubs subs state
                        |> List.length
                        |> equal 0
        ]
