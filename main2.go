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

type Firewall struct {
    date    string
    time    string
    action  string
    protocol    string
    srcip  string
    dstip  string
    srcport    int
    dstport    int
    size    string
    tcpflags    string
    tcpsyn  string
    tcpack  string
    tcpwin  string
    icmptype    string
    icmpcode    string
    info    string
    path    string
}

func main() {
    // read data from CSV file
    csvFile, err := os.Open("./large_pfirewall.log")

    if err != nil {
        fmt.Println(err)
    }

    defer csvFile.Close()

    reader := csv.NewReader(csvFile)

    reader.Comma = ' ' // use space-delimited instead of comma

    reader.FieldsPerRecord = -1

    // The below is the original reader that we got from the website
    //csvData, err := reader.ReadAll()
    //if err != nil {
    //    fmt.Println(err)
    //    os.Exit(1)
    //}

  for {
    record, err := reader.Read()
    if err == io.EOF {
      break
    }
    if err != nil {
      log.Fatal(err)
    }

    fmt.Println(record)
  }
}