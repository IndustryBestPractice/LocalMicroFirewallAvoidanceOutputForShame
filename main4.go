package main

import (
"encoding/csv"
"fmt"
"io"
"log"
"os"
"strings"
)


func main() {
    // Open CSV file
    csvFile, err := os.Open("/home/pi/IndustryBestPractice/lmfao/LocalMicroFirewallAvoidanceOutput/large_pfirewall.log")

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

    // Create variable to hold MERGE statements (create but with validation that it's unique)
    // These are creating the 
    var create strings.Builder
    create.WriteString("{\"statements\": [")

    // Create variable to hold relationships statements
    var relationships strings.Builder
    relationships.WriteString("{\"statements\": [")

    for {
        rec, err := reader.Read()

        // Do something with errors
        if err == io.EOF {
          break
        }
        if err != nil {
          log.Fatal(err)
        }

        // Write statement starter
        // "statement": "
        relationships.WriteString("{\"statement\": \"")

            // Define our global variables
            //var srcobjname string
            var srcobjversion string
            //var dstobjname string
            var dstobjversion string

            // Make src object  name
            if strings.Contains(rec[4], ".") {
                //srcobjname = strings.Replace(rec[4], ".", "_", -1)
                srcobjversion = "ipv4"
            } else {
                //srcobjname = strings.Replace(rec[4], ":", "_", -1)
                srcobjversion = "ipv6"
            }

            // Make dst object  name
            if strings.Contains(rec[5], ".") {
                //dstobjname = strings.Replace(rec[5], ".", "_", -1)
                dstobjversion = "ipv4"
            } else {
                //dstobjname = strings.Replace(rec[5], ":", "_", -1)
                dstobjversion = "ipv6"
            }

        // Creating the IP objects here - regardless of if it's a SEND or RECEIVE
            // we need both IP's to be created as their own objects anyways
        // Now creating the SRCIP obj
        // Start building the MERGE statement
        // MERGE (ipv4_10_20_72_186:ipv4 {ip:'10.20.72.186'})\n
        create.WriteString("{\"statement\": \"")
        create.WriteString("MERGE (variablename:" + srcobjversion + " {ip:'" + rec[4] + "'})\n")
        // Add closing line to the statement
        create.WriteString("},")

        // Now creating the DSTIP obj
        // Start building the MERGE statement
        // MERGE (ipv4_10_20_72_186:ipv4 {ip:'10.20.72.186'})\n
        create.WriteString("{\"statement\": \"")
        create.WriteString("MERGE (variablename:" + dstobjversion + " {ip:'" + rec[5] + "'})\n")
        // Add closing line to the statement
        create.WriteString("},")

        // We build different statements for RECEIVE vs SEND et. al.
        if rec[16] != "RECEIVE" {
            // LETS DO SEND!

            // Now creating the actual meat and potatoes
            relationships.WriteString("{\"statement\": \"")
            relationships.WriteString("MATCH (from:" + srcobjversion + " {ip:'" + rec[4] + "'})")
            relationships.WriteString("MATCH (to:" + dstobjversion + " {ip:'" + rec[5] + "'})")
            relationships.WriteString("MERGE (from)-[datatransfer:SENT {")

            //from_prt: ['3682'], \n
            relationships.WriteString("local_prt: ['" + rec[6]  + "'],\n")

            //to_prt: ['88'], \n
            relationships.WriteString("remote_prt: ['" + rec[7] + "'],\n")

            //protocol: ['UDP'], \n
            relationships.WriteString("protocol: ['" + rec[3] + "'],\n")

            //verdict: ['ALLOW'],\n
            relationships.WriteString("verdict: ['" + rec[2] + "'],\n")

            //datetime: ['2006-09-19 03:27:05']\n
            relationships.WriteString("datetime: ['" + rec[0] + " " + rec[1] + "']\n")

            //}]->(ipv4_10_20_72_186)\n
            relationships.WriteString("}]->(to)\n")
            relationships.WriteString("return datatransfer")
            relationships.WriteString("},")
        } else {
            // LETS DO RECEIVE!

            // Now creating the actual meat and potatoes
            relationships.WriteString("{\"statement\": \"")
            relationships.WriteString("MATCH (from:" + dstobjversion + " {ip:'" + rec[5] + "'})")
            relationships.WriteString("MATCH (to:" + srcobjversion + " {ip:'" + rec[4] + "'})")
            relationships.WriteString("MERGE (to)<-[datatransfer:RECEIVED {")

            //from_prt: ['3682'], \n
            relationships.WriteString("local_prt: ['" + rec[7]  + "'],\n")

            //to_prt: ['88'], \n
            relationships.WriteString("remote_prt: ['" + rec[6] + "'],\n")

            //protocol: ['UDP'], \n
            relationships.WriteString("protocol: ['" + rec[3] + "'],\n")

            //verdict: ['ALLOW'],\n
            relationships.WriteString("verdict: ['" + rec[2] + "'],\n")

            //datetime: ['2006-09-19 03:27:05']\n
            relationships.WriteString("datetime: ['" + rec[0] + " " + rec[1] + "']\n")

            //}]->(ipv4_10_20_72_186)\n
            // This is the new way
            relationships.WriteString("}]-(from)\n")
            relationships.WriteString("return datatransfer")
            relationships.WriteString("},")
        }

        //pfw.Date = rec[0]
        //pfw.Time = rec[1]
        //pfw.Action = rec[2]
        //pfw.Protocol = rec[3]
        //pfw.Srcip = rec[4]
        //pfw.Dstip = rec[5]
        //pfw.Srcport = rec[6]
        //pfw.Dstport = rec[7]
        //pfw.Size = rec[8]
        //pfw.Tcpflags = rec[9]
        //pfw.Tcpsyn = rec[10]
        //pfw.Tcpack = rec[11]
        //pfw.Tcpwin = rec[12]
        //pfw.Icmptype = rec[13]
        //pfw.Icmpcode = rec[14]
        //pfw.Info = rec[15]
        //pfw.Path = rec[16]
    }

    // Write the closing lines
    create.WriteString("]}")
    relationships.WriteString("]}")
    //fmt.Println(create.String())
    //fmt.Println(relationships.String())
}
