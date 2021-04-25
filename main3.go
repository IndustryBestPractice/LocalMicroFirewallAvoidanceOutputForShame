package main

import (
"encoding/csv"
"fmt"
"io"
"log"
"os"
"encoding/json"
//"strconv"
)

type PFirewall struct {
    Date      string   `json:"date"`
    Time      string   `json:"time"`
    Action    string   `json:"action"`
    Protocol  string   `json:"protocol"`
    Srcip     string   `json:"srcip"`
    Dstip     string   `json:"dstip"`
    Srcport   string   `json:"srcport"`
    Dstport   string   `json:"dstport"`
    Size      string   `json:"size"`
    Tcpflags  string   `json:"tcpflags"`
    Tcpsyn    string   `json:"tcpsyn"`
    Tcpack    string   `json:"tcpack"`
    Tcpwin    string   `json:"tcpwin"`
    Icmptype  string   `json:"icmptype"`
    Icmpcode  string   `json:"icmpcode"`
    Info      string   `json:"info"`
    Path      string   `json:"path"`
}

func main() {
    // Open CSV file
    csvFile, err := os.Open("./large_pfirewall.log")

    if err != nil {
        fmt.Println(err)
    }

    defer csvFile.Close()

    // Read CSV file
    reader := csv.NewReader(csvFile)

    // Set delimeter to a space instead of a comma
    reader.Comma = ' '
    // Set comment to # sign because WINDOWS JUST GOTTA BE DIFFICULT LIKE THAT
    reader.Comment = '#'

    // Read all fields per record read
    reader.FieldsPerRecord = -1

    // Create array variable called data
    //var data [][]string

    // Add the CSV header to the array variable we made
    //data = append(data, []string{"date","time","action","protocol","src-ip","dst-ip","src-port","dst-port","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})

    // Foreach
  //for {
    // record line that we read from reader
    //record, err := reader.Read()
    //if err == io.EOF {
    //  break
    //}
    //if err != nil {
    //  log.Fatal(err)
    //}

    //fmt.Println(record)
    // Append to the array we generated earlier
    //data = append(data,record)
  //}

    // Print the records to the screen to verify it worked
    //for i := 0; i < len(data); i++ {
    //    fmt.Println(data[i])
    //}    

    var pfw PFirewall
    var pfirewalls []PFirewall

    // Just for giggles lets read the CSV file raw
    //records, err := reader.ReadAll()

    //for _, rec := range data {
    for {
        rec, err := reader.Read()
        if err == io.EOF {
          break
        }
        if err != nil {
          log.Fatal(err)
        }
        pfw.Date = rec[0]
        pfw.Time = rec[1]
        pfw.Action = rec[2]
        pfw.Protocol = rec[3]
        pfw.Srcip = rec[4]
        pfw.Dstip = rec[5]
        pfw.Srcport = rec[6]
        pfw.Dstport = rec[7]
        pfw.Size = rec[8]
        pfw.Tcpflags = rec[9]
        pfw.Tcpsyn = rec[10]
        pfw.Tcpack = rec[11]
        pfw.Tcpwin = rec[12]
        pfw.Icmptype = rec[13]
        pfw.Icmpcode = rec[14]
        pfw.Info = rec[15]
        pfw.Path = rec[16]
        // Take converted data and add it to the array
        pfirewalls = append(pfirewalls, pfw)
    }

    // Convert to JSON
    json_data, err := json.Marshal(pfirewalls)
    if err != nil {
        fmt.Println("Error occured!")
        fmt.Println(err)
        os.Exit(1)
    }
    // print JSON data
    fmt.Println(string(json_data))
}