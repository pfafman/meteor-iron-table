Meteor-Iron-Table
====================

Paging Table for IronRouter and Meteor.  Only downloads the current page to the client and also is set up for inline editing and a light schema.

## Installation

* Pre-Install [Meteorite](https://github.com/oortcloud/meteorite) 

```sh
    [sudo] npm install -g meteorite
```

Note this is not on Atmosphere yet due to alpha nature.  I really want to re-write the whole thing to use more of Meteor and Iron Router 1.0+ featrue set.

You can add it if you want by editing/creating a meteor upper level smart.json file with a "git" entry:

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

## Demo

http://iron-table-test.meteor.com


## License

MIT