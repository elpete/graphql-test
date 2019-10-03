component {

    variables.luke = {
        id: "1000",
        name: "Luke Skywalker",
        friends: [ "1002", "1003", "2000", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        homePlanet: "Tatooine"
    };

    variables.vader = {
        id: "1001",
        name: "Darth Vader",
        friends: [ "1004" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        homePlanet: "Tatooine",
    };

    variables.han = {
        id: "1002",
        name: "Han Solo",
        friends: [ "1000", "1003", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
    };

    variables.leia = {
        id: "1003",
        name: "Leia Organa",
        friends: [ "1000", "1002", "2000", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        homePlanet: "Alderaan",
    };

    variables.tarkin = {
        id: "1004",
        name: "Wilhuff Tarkin",
        friends: [ "1001" ],
        appearsIn: [ "NEWHOPE" ],
    };

    variables.humans = {
        "1000": variables.luke,
        "1001": variables.vader,
        "1002": variables.han,
        "1003": variables.leia,
        "1004": variables.tarkin,
    };

    variables.threepio = {
        id: "2000",
        name: "C-3PO",
        friends: [ "1000", "1002", "1003", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        primaryFunction: "Protocol",
    };

    variables.artoo = {
        id: "2001",
        name: "R2-D2",
        friends: [ "1000", "1002", "1003" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        primaryFunction: "Astromech",
    };

    variables.droids = {
        "2000": variables.threepio,
        "2001": variables.artoo,
    };

    function index( event, rc, prc ) {
        var schema = fileRead( expandPath( "/resources/graphql/starwars.graphql" ) );

        var schemaParser = createObject( "java", "graphql.schema.idl.SchemaParser" ).init();
        var typeDefinitionRegistry = schemaParser.parse( schema );

        var runtimeWiring = createObject( "java", "graphql.schema.idl.RuntimeWiring" )
            .newRuntimeWiring()
            .type(
                createObject( "java", "graphql.schema.idl.TypeRuntimeWiring" )
                    .newTypeWiring( "QueryType" )
                    .dataFetcher( "hero", createDynamicProxy(
                        new models.proxies.DataFetcher( function( environment ) {
                            return variables.artoo;
                        } ),
                        [ "graphql.schema.DataFetcher" ]
                    ) )
                    .dataFetcher( "human", createDynamicProxy(
                        new models.proxies.DataFetcher( function( environment ) {
                            return variables.humans[ arguments.environment.getArguments().get( "id" ) ];
                        } ),
                        [ "graphql.schema.DataFetcher" ]
                    ) )
                    .dataFetcher( "droid", createDynamicProxy(
                        new models.proxies.DataFetcher( function( environment ) {
                            return variables.droids[ arguments.environment.getArguments().get( "id" ) ];
                        } ),
                        [ "graphql.schema.DataFetcher" ]
                    ) )
            )
            .type(
                createObject( "java", "graphql.schema.idl.TypeRuntimeWiring" )
                    .newTypeWiring( "Human" )
                    .dataFetcher( "friends", getFriendsDataFetcher() )
            )
            .type(
                createObject( "java", "graphql.schema.idl.TypeRuntimeWiring" )
                    .newTypeWiring( "Droid" )
                    .dataFetcher( "friends", getFriendsDataFetcher() )
            )
            .type(
                createObject( "java", "graphql.schema.idl.TypeRuntimeWiring" )
                    .newTypeWiring( "Character" )
                    .typeResolver( createDynamicProxy(
                        new models.proxies.TypeResolver( function( env ) {
                            var id = arguments.env.getObject().get( "id" );
                            if ( variables.humans.keyExists( id ) ) {
                                return env.getSchema().getObjectType( "Human" );
                            }
                            if ( variables.droids.keyExists( id ) ) {
                                return env.getSchema().getObjectType( "Droid" );
                            }
                            return;
                        } ),
                        [ "graphql.schema.TypeResolver" ]
                    ) )
            )
            .build()

        var schemaGenerator = createObject( "java", "graphql.schema.idl.SchemaGenerator" ).init();
        var graphQLSchema = schemaGenerator.makeExecutableSchema( typeDefinitionRegistry, runtimeWiring );

        var build = createObject( "java", "graphql.GraphQL" ).newGraphQL( graphQLSchema ).build();
        var body = event.getHTTPContent( json = true );
        if ( ! isStruct( body ) ) {
            event.renderData(
                type = "json",
                statusCode = 500,
                data = {
                    "errors": "Invalid body. Received [#body#]"
                }
            );
            return;
        }
        var executionResult = build.execute( body.query );

        if ( executionResult.isDataPresent() ) {
            event.renderData(
                type = "json",
                statusCode = 200,
                data = executionResult.getData()
            );
        } else {
            event.renderData(
                type = "json",
                statusCode = 500,
                data = {
                    "errors": arrayMap( executionResult.getErrors(), function( error ) {
                        return error.getMessage();
                    } )
                }
            );
        }

    }

    private function getFriendsDataFetcher() {
        return createDynamicProxy(
            new models.proxies.DataFetcher( function( environment ) {
                var friends = [];
                for ( var id in arguments.environment.getSource().get( "friends" ) ) {
                    var character = getCharacter( id );
                    if ( ! isNull( character ) ) {
                        friends.append( character );
                    }
                }
                return friends;
            } ),
            [ "graphql.schema.DataFetcher" ]
        );
    }

    private function getCharacter( required string id ) {
        if ( variables.humans.keyExists( id ) ) {
            return variables.humans[ id ];
        }

        if ( variables.droids.keyExists( id ) ) {
            return variables.droids[ id ];
        }

        return;
    }

}
