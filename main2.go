package main

import (
"encoding/csv"
"fmt"
"io"
"log"
"os"
//"encoding/json"
//"strconv"
)

func main() {
    // read data from CSV file
    csvFile, err := os.Open("./large_pfirewall.log")

    if err != nil {
        fmt.Println(err)
    }

    // Manually create CSV file!
    //in := `# This is also a comment
//first_name,last_name,username
//# This is a comment
//"Rob","Pike",rob
//Ken,Thompson,ken
//"Robert","Griesemer","gri"
//`
    //r := csv.NewReader(strings.NewReader(in))

    defer csvFile.Close()

    reader := csv.NewReader(csvFile)

    reader.Comma = ' ' // use space-delimited instead of comma
    reader.Comment = '#' // use # as the comment character because WINDOWS GONNA WINDOW DAWG

    reader.FieldsPerRecord = -1

    var data [][]string
    //data = append(data, []string{"fname", "lname", "fullname"})
    data = append(data, []string{"date","time","action","protocol","src-ip","dst-ip","src-port","dst-port","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})

  for {
    record, err := reader.Read()
    if err == io.EOF {
      break
    }
    if err != nil {
      log.Fatal(err)
    }

    //fmt.Println(record)
    data = append(data,record)
  }

    for i := 0; i < len(data); i++ {
        fmt.Println(data[i])
    }
}