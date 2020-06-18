{
    "files": [
      {
          "aql": {
            "items.find": {
                "type":"file",
                "stat.downloads":{"$lte":"1"},
                "stat.downloaded":{"$before":"1d"},
                "repo":{"$nmatch":"*prod*"}
            }
          }
        }
    ]
}
