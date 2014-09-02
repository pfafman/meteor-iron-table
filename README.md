Meteor-Iron-Table
====================

Paging Table for IronRouter and Meteor.  Only downloads the current page to the client and also is set up for inline editing and a light schema.

## Installation

* Pre-Install [Meteorite](https://github.com/oortcloud/meteorite) to use [Atmosphere](https://atmosphere.meteor.com)

```sh
    [sudo] npm install -g meteorite
```

Note this is not on Atmosphere yet.  You can add it if you want by editing your meteor upper level smart.json file with a "git" entry:

```
{
    "packages": {
        "pfafman:iron-table": {
            "git": "https://github.com/pfafman/meteor-iron-table.git"
        },
        ....
    }
}
```
and then run meteorite to install.

```
    mrt add pfafman:iron-table
```

##Usage

TODO:  Currently needs some TLC to get to work and I have not documented all the steps.


## License

MIT