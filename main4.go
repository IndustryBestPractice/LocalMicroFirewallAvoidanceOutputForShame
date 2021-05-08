package main

import (
"encoding/csv"
"fmt"
"io"
"log"
"os"
"strings"
//"strconv"
)

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

    // Delete files if they already exist
	err = os.Remove("/data/send_data.csv")
    if err != nil {
        fmt.Println(err)
    }
	err = os.Remove("/data/receive_data.csv")
    if err != nil {
        fmt.Println(err)
    }
	err = os.Remove("/data/forward_data.csv")
    if err != nil {
        fmt.Println(err)
    }
	err = os.Remove("/data/unknown_data.csv")
    if err != nil {
        fmt.Println(err)
    }

	// Create file system objects for the new files
	send_file,err := os.Create("/data/send_data.csv")
	if err != nil {
		fmt.Println(err)
			send_file.Close()
		//os.Exit(1)
	}
	receive_file,err := os.Create("/data/receive_data.csv")
	if err != nil {
		fmt.Println(err)
			receive_file.Close()
		//os.Exit(1)
	}
	forward_file,err := os.Create("/data/forward_data.csv")
	if err != nil {
		fmt.Println(err)
			forward_file.Close()
		//os.Exit(1)
	}
	unknown_file,err := os.Create("/data/unknown_data.csv")
	if err != nil {
		fmt.Println(err)
			unknown_file.Close()
		//os.Exit(1)
	}

	// Create file writer
	send_writer := csv.NewWriter(send_file)
	defer send_writer.Flush()
	receive_writer := csv.NewWriter(receive_file)
	defer receive_writer.Flush()
	forward_writer := csv.NewWriter(forward_file)
	defer forward_writer.Flush()
	unknown_writer := csv.NewWriter(unknown_file)
	defer unknown_writer.Flush()

	err = send_writer.Write([]string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
	if err != nil {
		fmt.Println(err)
		return
	}
	err = receive_writer.Write([]string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
	if err != nil {
		fmt.Println(err)
		return
	}
	err = forward_writer.Write([]string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
	if err != nil {
		fmt.Println(err)
		return
	}
	err = unknown_writer.Write([]string{"srcipver","dstipver","date","time","action","protocol","srcip","dstip","srcport","dstport","size","tcpflags","tcpsyn","tcpack","tcpwin","icmptype","icmpcode","info","path"})
	if err != nil {
		fmt.Println(err)
		return
	}

	records, err := reader.ReadAll()

  //for {
	for i := 0; i < len(records); i++ {
		//rec, err := reader.Read()
		//fmt.Println("Checking line number: " + strconv.Itoa(i))
		rec := records[i]
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
			err := send_writer.Write([]string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
			if err != nil {
				fmt.Println(err)
				return
			}
		} else if rec[16] == "RECEIVE" {
			err := receive_writer.Write([]string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
			if err != nil {
				fmt.Println(err)
				return
			}
		} else if rec[16] == "FORWARD" {
			err := forward_writer.Write([]string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
			if err != nil {
				fmt.Println(err)
				return
			}
		} else {
			err := unknown_writer.Write([]string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
			fmt.Println("Hello")
			fmt.Println([]string{srcobjversion,dstobjversion,rec[0],rec[1],rec[2],rec[3],rec[4],rec[5],rec[6],rec[7],rec[8],rec[9],rec[10],rec[11],rec[12],rec[13],rec[14],rec[15],rec[16]})
			fmt.Println("world!")
			if err != nil {
				fmt.Println(err)
				return
			}
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

  	//send_file.Close()
    fmt.Println("Created Send file!")
	//receive_file.Close()
	fmt.Println("Created Receive file!")
	//forward_file.Close()
	fmt.Println("Created Forward file!")
	//unknown_file.Close()
	fmt.Println("Created Unknown file!")

    //for i := 0; i < len(send_data); i++ {
    //    fmt.Println(send_data[i])
    //}
	// NEW LINE
}
