package main

// To execute program, run the below in the command line
// go run main.go
import (
  "encoding/csv"
  "fmt"
  "io"
  "log"
  "os"
)

func main() {
  csv_file, _ := os.Open("./large_pfirewall.csv")
  r := csv.NewReader(csv_file)

  for {
    record, err := r.Read()
    if err == io.EOF {
      break
    }
    if err != nil {
      log.Fatal(err)
    }

    fmt.Println(record)
  }
}