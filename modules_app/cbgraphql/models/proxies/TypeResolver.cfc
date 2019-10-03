component {

    property name="callback";

    function init( required callback ) {
        variables.callback = arguments.callback;
        return this;
    }

    function getType( env ) {
        return variables.callback( arguments.env );
    }

}
