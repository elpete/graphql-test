component {

    property name="callback";

    function init( required callback ) {
        variables.callback = arguments.callback;
        return this;
    }

    function getComparator( required environment ) {
        return variables.callback( arguments.environment );
    }

}
