
#ifndef BLUETOOTH_H
#define BLUETOOTH_H

#include <Streaming.h>
#include <SPI.h>
#include <ble.h>
#include <stdint.h>
#include <Arduino.h>
#include "ledBracelet.h"

#define PACKET_HDR_SIZE 3
#define MAX_BUFFER_SIZE (12) // the number of bytes stored in the serial buffer

typedef struct Packet {
  uint8_t msgLen;
  uint8_t ledIndex;
  uint8_t data[MAX_BUFFER_SIZE];
};
  

void printBuf(int nBytes, uint8_t *buf) {
    if (nBytes > 0) {
      DPRINT(p("BT:");)
      for (int i=0; i<nBytes; i++) {
        DPRINT(p((uint8_t)buf[i]); p(" ");)
      }
      DPRINT(p("\n");)
    }
}

class Bluetooth {
 public:
  
  Bluetooth() {
    SPI.begin();
    SPI.setDataMode(SPI_MODE0);
    SPI.setBitOrder(LSBFIRST);
    SPI.setClockDivider(SPI_CLOCK_DIV16); 
  
    isConn = false;
  }


  void start() {  
    ble_begin();  
    ble_do_events();  
  }


  boolean isConnected() { return isConn; }


  // call often; required for handshaking e.g.
  // arguments are callbacks to invoke when the connection is established and broken
  Packet *loop() {
    ble_do_events();  

    boolean bleConn = ble_connected();
    if (bleConn && !isConn) {
      isConn = true;
      DPRINT(p("Bluetooth connection active\n");)
    } else if (!bleConn && isConn) {
      isConn = false;
      DPRINT(p("Bluetooth connection broken\n");)
    }      
    
    if (isConn)
      return receivePacket();
    else
      return NULL;
  }
  
  
  // send data of given size
  void sendBTData(byte *dataPtr, int numBytes) {
    for (int i=0; i<numBytes; i++) {
      ble_write(dataPtr[i]);
    }
  }

 
 private:  
  // receive data into the given array of given size
  int receiveBTData(uint8_t *dataPtr, int maxBytes) {
    int currentByte = 0;
    while (ble_available() && currentByte < maxBytes) {
      uint8_t c = ble_read();  
      dataPtr[currentByte++] = c;
    }
    return currentByte;
  }
  
  Packet *receivePacket() {
    uint8_t buf[PACKET_HDR_SIZE];
    int nBytes = receiveBTData(buf, PACKET_HDR_SIZE);
    printBuf(nBytes, buf);
    
    if (nBytes == PACKET_HDR_SIZE) {
      packet.msgType = buf[0];
      packet.msgLen = (unsigned int)buf[2];
      DPRINT(Serial << "Received packet with length " << packet.msgLen << "\n";)
      
      if (packet.msgLen > 0) {
        nBytes = receiveBTData(packet.data, MAX_BUFFER_SIZE);
        printBuf(nBytes, packet.data);
        if (nBytes == packet.msgLen) {
          DPRINT(Serial << "Valid packet received of size " << nBytes << "\n";)
          return &packet;
        } else {
          DPRINT(Serial << "Invalid packet received of size " << nBytes << " (expected " << packet.msgLen << ")\n";)
        }
      } else {
        DPRINT(Serial << "Invalid packet with data of size 0\n";)
      }
    } else if (nBytes > 0) {
      DPRINT(Serial << "Received invalid packet of size " << nBytes << "\n";)
    }      
    return NULL;
  }
  
  private:
    Packet packet;
    boolean isConn;
};


#endif


