component {

    this.luke = {
        id: "1000",
        name: "Luke Skywalker",
        friends: [ "1002", "1003", "2000", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        homePlanet: "Tatooine"
    };

    this.vader = {
        id: "1001",
        name: "Darth Vader",
        friends: [ "1004" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        homePlanet: "Tatooine",
    };

    this.han = {
        id: "1002",
        name: "Han Solo",
        friends: [ "1000", "1003", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
    };

    this.leia = {
        id: "1003",
        name: "Leia Organa",
        friends: [ "1000", "1002", "2000", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        homePlanet: "Alderaan",
    };

    this.tarkin = {
        id: "1004",
        name: "Wilhuff Tarkin",
        friends: [ "1001" ],
        appearsIn: [ "NEWHOPE" ],
    };

    this.humans = {
        "1000": this.luke,
        "1001": this.vader,
        "1002": this.han,
        "1003": this.leia,
        "1004": this.tarkin,
    };

    this.threepio = {
        id: "2000",
        name: "C-3PO",
        friends: [ "1000", "1002", "1003", "2001" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        primaryFunction: "Protocol",
    };

    this.artoo = {
        id: "2001",
        name: "R2-D2",
        friends: [ "1000", "1002", "1003" ],
        appearsIn: [ "NEWHOPE", "EMPIRE", "JEDI" ],
        primaryFunction: "Astromech",
    };

    this.droids = {
        "2000": this.threepio,
        "2001": this.artoo,
    };

}
