package main

import (
"encoding/csv"
"fmt"
"io"
"log"
"os"
"strings"
)

func create_files(datatype string,inputdataarray [][]string) {
    // Delete files if they already exist
    err := os.Remove("/data/" + datatype + "_data.csv")
    if err != nil {
        fmt.Println(err)
    }

    // Create file system objects for the new files
    data_file,err := os.Create("/data/" + datatype + "_data.csv")
    if err != nil {
        fmt.Println(err)
            data_file.Close()
        //os.Exit(1)
    }

	// Write our files!
	send_writer := csv.NewWriter(data_file)
    defer send_writer.Flush()
    for _, value := range inputdataarray {
        err := send_writer.Write(value)
		if err != nil {
			fmt.Println(err)
			return
		}
    }
	err = data_file.Close()
    if err != nil {
        fmt.Println(err)
        return
    }
}

func main() {
    // read data from CSV file
	// How to read windows firewall log: https://www.howtogeek.com/220204/how-to-track-firewall-activity-with-the-windows-firewall-log/
    csvFile, err := os.Open("/data/large_pfirewall.log")

    if err != nil {
        fmt.Println(err)
    }

    defer csvFile.Close()

    reader := csv.NewReader(csvFile)

    reader.Comma = ' ' // use space-delimited instead of comma
    reader.Comment = '#' // use # as the comment character because WINDOWS GONNA WINDOW DAWG

    reader.FieldsPerRecord = -1

    var send_data [][]string
	var receive_data [][]string
	var forward_data [][]string
	var unknown_data [][]string
    //data = append(data, []string{"fname", "lname", "fullname"})
    send_data = append(send_data, []string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
	receive_data = append(receive_data, []string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
	forward_data = append(forward_data, []string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
	unknown_data = append(unknown_data, []string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
    // If we wanted to remove the header row, follow the below link
    // https://github.com/ahmagdy/CSV-To-JSON-Converter/blob/master/main.go

  for {
		rec, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}

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

		// Path displays the direction of the communication. The options available are:
		// SEND, RECEIVE, FORWARD, and UNKNOWN.
        // We build different statements for RECEIVE vs SEND et. al.
		if rec[16] == "SEND" {
			send_data = append(send_data, []string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
		} else if rec[16] == "RECEIVE" {
			receive_data = append(receive_data, []string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
		} else if rec[16] == "FORWARD" {
			forward_data = append(forward_data, []string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
		} else {
			unknown_data = append(unknown_data, []string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
		}

    //fmt.Println(record)
    //data = append(data,record)
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

  	create_files("send", send_data)
    fmt.Println("Created Send file!")
	create_files("receive", receive_data)
	fmt.Println("Created Receive file!")
	create_files("forward", forward_data)
	fmt.Println("Created Forward file!")
	create_files("unknown", unknown_data)
	fmt.Println("Created Unknown file!")

    //for i := 0; i < len(send_data); i++ {
    //    fmt.Println(send_data[i])
    //}
}
