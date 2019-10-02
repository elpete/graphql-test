component {

    variables.luke = {
            id        : '1000',
            name      : 'Luke Skywalker',
            friends   : ['1002', '1003', '2000', '2001'],
            appearsIn : [4, 5, 6],
            homePlanet: 'Tatooine'
    };

    variables.vader = {
            id        : '1001',
            name      : 'Darth Vader',
            friends   : ['1004'],
            appearsIn : [4, 5, 6],
            homePlanet: 'Tatooine',
    };

    variables.han = {
            id       : '1002',
            name     : 'Han Solo',
            friends  : ['1000', '1003', '2001'],
            appearsIn: [4, 5, 6],
    };

    variables.leia = {
            id        : '1003',
            name      : 'Leia Organa',
            friends   : ['1000', '1002', '2000', '2001'],
            appearsIn : [4, 5, 6],
            homePlanet: 'Alderaan',
    };

    variables.tarkin = {
            id       : '1004',
            name     : 'Wilhuff Tarkin',
            friends  : ['1001'],
            appearsIn: [4],
    };

    variables.humans = {
        '1000': variables.luke,
        '1001': variables.vader,
        '1002': variables.han,
        '1003': variables.leia,
        '1004': variables.tarkin,
    };

    variables.threepio = {
            id             : '2000',
            name           : 'C-3PO',
            friends        : ['1000', '1002', '1003', '2001'],
            appearsIn      : [4, 5, 6],
            primaryFunction: 'Protocol',
    };

    variables.artoo = {
            id             : '2001',
            name           : 'R2-D2',
            friends        : ['1000', '1002', '1003'],
            appearsIn      : [4, 5, 6],
            primaryFunction: 'Astromech',
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
                            return variables.humans[ arguments.environment.getArguments().id ];
                        } ),
                        [ "graphql.schema.DataFetcher" ]
                    ) )
                    .dataFetcher( "droid", createDynamicProxy(
                        new models.proxies.DataFetcher( function( environment ) {
                            return variables.droids[ arguments.environment.getArguments().id ];
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
                    .typeResolver( getCharacterTypeResolver() )
            )
            .build()

        var schemaGenerator = createObject( "java", "graphql.schema.idl.SchemaGenerator" ).init();
        var graphQLSchema = schemaGenerator.makeExecutableSchema( typeDefinitionRegistry, runtimeWiring );

        var build = createObject( "java", "graphql.GraphQL" ).newGraphQL( graphQLSchema ).build();
        var body = event.getHTTPContent( json = true );
        param body.query = "";
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

    private function getCharacter( required string id ) {
        if ( variables.humans.keyExists( id ) ) {
            return variables.humans[ id ];
        }

        if ( variables.droids.keyExists( id ) ) {
            return variables.droids[ id ];
        }

        return;
    }

    private function getEpisodeEnum() {
        return createObject( "java", "graphql.schema.GraphQLEnumType" )
            .newEnum()
            .name( "Episode" )
            .description( "One of the films in the Star Wars Trilogy" )
            .value( "NEWHOPE", 4, "Released in 1977." )
            .value( "EMPIRE", 5, "Released in 1980." )
            .value( "JEDI", 6, "Released in 1983." )
            .comparatorRegistry( getByNameRegistry() )
            .build();
    }

    private function getCharacterInterface() {
        return createObject( "java", "graphql.schema.GraphQLInterfaceType" )
            .newInterface()
            .name( "Character" )
            .description( "A character in the Star Wars Trilogy" )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "id" )
                    .description( "The id of the character." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLNonNull" ).nonNull(
                            createObject( "java", "graphql.Scalars" ).GraphQLString
                        )
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "name" )
                    .description( "The name of the character." )
                    .type( createObject( "java", "graphql.Scalars" ).GraphQLString )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "friends" )
                    .description( "The friends of the character, or an empty list if they have none." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLList" ).list(
                            createObject( "java", "graphql.schema.GraphQLTypeReference" ).typeRef( "Character" )
                        )
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "appearsIn" )
                    .description( "Which movies they appear in." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLList" ).list(
                            getEpisodeEnum()
                        )
                    )
            )
            .typeResolver( getCharacterTypeResolver() )
            .comparatorRegistry(getByNameRegistry())
            .build();
    }

    private function getCharacterTypeResolver() {
        return createDynamicProxy(
            new models.proxies.TypeResolver( function( env ) {
                var id = arguments.env.getObject().id;
                if ( variables.humans.keyExists( id ) ) {
                    return getHumanType();
                }
                if ( variables.droids.keyExists( id ) ) {
                    return getDroidType();
                }
                return;
            } ),
            [ "graphql.schema.TypeResolver" ]
        );
    }

    private function getHumanType() {
        return createObject( "java", "graphql.schema.GraphQLObjectType" )
            .newObject()
            .name( "Human" )
            .description("A humanoid creature in the Star Wars universe.")
            .withInterface( getCharacterInterface() )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "id" )
                    .description( "The id of the human." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLNonNull" ).nonNull(
                            createObject( "java", "graphql.Scalars" ).GraphQLString
                        )
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "name" )
                    .description( "The name of the human." )
                    .type(
                        createObject( "java", "graphql.Scalars" ).GraphQLString
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "friends" )
                    .description( "The friends of the human, or an empty list if they have none." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLList" ).list(
                            getCharacterInterface()
                        )
                    )
                    .dataFetcher( getFriendsDataFetcher() )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "appearsIn" )
                    .description( "Which movies they appear in." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLList" ).list(
                            getEpisodeEnum()
                        )
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "homePlanet" )
                    .description( "The home planet of the human, or null if unknown." )
                    .type(
                        createObject( "java", "graphql.Scalars" ).GraphQLString
                    )
            )
            .comparatorRegistry(
                getByNameRegistry()
            )
            .build();
    }

    private function getDroidType() {
        return createObject( "java", "graphql.schema.GraphQLObjectType" )
            .newObject()
            .name( "Droid" )
            .description( "A mechanical creature in the Star Wars universe." )
            .withInterface( getCharacterInterface() )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "id" )
                    .description( "The id of the droid." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLNonNull" ).nonNull(
                            createObject( "java", "graphql.Scalars" ).GraphQLString
                        )
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "name" )
                    .description( "The name of the droid." )
                    .type(
                        createObject( "java", "graphql.Scalars" ).GraphQLString
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "friends" )
                    .description( "The friends of the droid, or an empty list if they have none." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLList" ).list(
                            getCharacterInterface()
                        )
                    )
                    .dataFetcher( getFriendsDataFetcher() )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "appearsIn" )
                    .description( "Which movies they appear in." )
                    .type(
                        createObject( "java", "graphql.schema.GraphQLList" ).list(
                            getEpisodeEnum()
                        )
                    )
            )
            .field(
                createObject( "java", "graphql.schema.GraphQLFieldDefinition" )
                    .newFieldDefinition()
                    .name( "primaryFunction" )
                    .description( "The primary function of the droid." )
                    .type(
                        createObject( "java", "graphql.Scalars" ).GraphQLString
                    )
            )
            .comparatorRegistry(
                getByNameRegistry()
            )
            .build();
    }

    private function getFriendsDataFetcher() {
        return createDynamicProxy(
            new models.proxies.DataFetcher( function( environment ) {
                var friends = [];
                for ( var id in arguments.environment.getSource().friends ) {
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

    private function getByNameRegistry() {
        return createDynamicProxy(
            new models.proxies.GraphqlTypeComparatorRegistry( function( environment ) {
                return createObject( "java", "graphql.schema.GraphqlTypeComparators" ).byNameAsc()
            } ),
            [ "graphql.schema.GraphqlTypeComparatorRegistry" ]
        );
    }

}
