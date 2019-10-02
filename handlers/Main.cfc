component extends="coldbox.system.EventHandler" {

    // Default Action
	function index( event, rc, prc ) {
        var schema = "type Query{hello: String}";

        var schemaParser = createObject( "java", "graphql.schema.idl.SchemaParser" ).init();
        var typeDefinitionRegistry = schemaParser.parse( schema );

        var dataFetcher = createDynamicProxy(
            new models.proxies.DataFetcher( function( environment ) {
                return "world";
            } ),
            [ "graphql.schema.DataFetcher" ]
        );

        var typeRuntimeWiringBuilder = createObject( "java", "graphql.schema.idl.TypeRuntimeWiring" )
            .newTypeWiring( "Query" )
            .dataFetcher( "hello", dataFetcher );

        var runtimeWiring = createObject( "java", "graphql.schema.idl.RuntimeWiring" )
            .newRuntimeWiring()
            .type( typeRuntimeWiringBuilder )
            .build();

        var schemaGenerator = createObject( "java", "graphql.schema.idl.SchemaGenerator" ).init();
        var graphQLSchema = schemaGenerator.makeExecutableSchema( typeDefinitionRegistry, runtimeWiring );

        var build = createObject( "java", "graphql.GraphQL" ).newGraphQL( graphQLSchema ).build();
        var executionResult = build.execute( "{hello}" );

		event.renderData( type = "json", data = executionResult.getData() );
	}

	/************************************** IMPLICIT ACTIONS *********************************************/

	function onAppInit(event,rc,prc){

	}

	function onRequestStart(event,rc,prc){

	}

	function onRequestEnd(event,rc,prc){

	}

	function onSessionStart(event,rc,prc){

	}

	function onSessionEnd(event,rc,prc){
		var sessionScope = event.getValue("sessionReference");
		var applicationScope = event.getValue("applicationReference");
	}

	function onException(event,rc,prc){
		event.setHTTPHeader( statusCode = 500 );
		//Grab Exception From private request collection, placed by ColdBox Exception Handling
		var exception = prc.exception;
		//Place exception handler below:
	}

}
