#include "Timer.h"
#include "HomeChallenge1.h"


module HomeChallenge1C @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
  	interface Timer<TMilli> as Timer1;
  	interface Timer<TMilli> as Timer2;
  	interface Timer<TMilli> as Timer3;
    interface SplitControl as AMControl;
    interface Packet;
  }
 }
 implementation {

  message_t packet; //definisce un messaggio chiamato packet

  bool locked;
  uint16_t counter = 0; //integer (unsigned integer 16 bytes) for a counter
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer1.startPeriodic(200);
      call Timer2.startPeriodic(333);
      call Timer3.startPeriodic(1000);
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void Timer1.fired() {

    if (locked) {
      return;
    }
    else {
    if(TOS_NODE_ID == 3){
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t)); 
      if (rcm == NULL) {
	return;
      }
	  rcm->sender_id= TOS_NODE_ID;
      rcm->counter = counter;//associa il contatore che stiamo incrementando all'attributo di rcm
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
      //nell'if stiamo mandando il messaggio in BROADCAST

	locked = TRUE; //send the message and lock the variable
      }
     }
    }
  }
  
    event void Timer2.fired() {

    if (locked) {
      return;
    }
    else {
    if(TOS_NODE_ID == 2){
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t)); 
      if (rcm == NULL) {
	return;
      }
	  rcm->sender_id= TOS_NODE_ID;
      rcm->counter = counter;//associa il contatore che stiamo incrementando all'attributo di rcm
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
      //nell'if stiamo mandando il messaggio in BROADCAST

	locked = TRUE; //send the message and lock the variable
      }
     }
    }
  }
	
	  event void Timer3.fired() {

    if (locked) {
      return;
    }
    else {
    if(TOS_NODE_ID == 1){
      radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t)); 
      if (rcm == NULL) {
	return;
      }
	  rcm->sender_id= TOS_NODE_ID;
      rcm->counter = counter;//associa il contatore che stiamo incrementando all'attributo di rcm
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
      //nell'if stiamo mandando il messaggio in BROADCAST

	locked = TRUE; //send the message and lock the variable
      }
     }
    }
  }
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
	counter++;

    if (len != sizeof(radio_count_msg_t)) {return bufPtr;}
    else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      if((rcm->counter % 10) == 0){
      	call Leds.led0Off();
      	call Leds.led1Off();
      	call Leds.led2Off();
      }else{
      	if(rcm->sender_id == 1){
      		call Leds.led0Toggle(); //led rosso
      	}
      	if(rcm->sender_id == 2){
      		call Leds.led1Toggle(); 
      	}      	
      	if(rcm->sender_id == 3){
      		call Leds.led2Toggle(); 
      	}
      }
      return bufPtr;
    }
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE; //unlock when it is sent
    }
  }
 }
