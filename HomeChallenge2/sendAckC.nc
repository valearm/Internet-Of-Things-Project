/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
    interface SplitControl;
	//interface for timer
	interface Timer<TMilli> as MilliTimer;
	interface Timer<TMilli> as StopTimer1;
    //other interfaces, if needed
	interface Packet;
    interface AMSend;
    interface Receive;
    interface PacketAcknowledgements;
    	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  message_t packet;

 void sendReq();
 void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
  
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg */
	 my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	 if (mess == NULL) {
		return;
	  }
	  counter++;
	  dbg("role", "mote_%u incremented counter %d\n",TOS_NODE_ID, counter);
	  dbg("radio_pack","Preparing the message... \n");
	  mess->msg_type= rec_id; //Set the type of message as REQ
	  mess->msg_counter = counter; //Set properly the counter 
	  
	  
	 /*
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 */
	 /*
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */ 
	 if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS){
	 	dbg("radio_ack","Set the ACK flag for the message...\n");
	 	if(call AMSend.send(2, &packet,sizeof(my_msg_t)) == SUCCESS){
	    	dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	    	dbg_clear("radio_pack","\t Payload Sent\n" );
			dbg_clear("radio_pack", "\t\t type: REQ(coded as:%hhu )\n ", mess->msg_type);
		 	dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
		 	dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->msg_counter);
			
		
  		}
	 }else{
		dbg("radio_ack","ACK Packet error\n");	
		dbg("radio_pack","Since ACK error, no packet is sent\n");			
	 }
 }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read one.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted on node %u.\n", TOS_NODE_ID);
	/* Fill it ... */
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
    /* Fill it ... */
         
    if(err == SUCCESS) {
    	dbg("radio", "Radio on of mote %u!\n", TOS_NODE_ID);
		if (TOS_NODE_ID == 1){
           call MilliTimer.startPeriodic( 1000 );
           dbg("timer", "Timer of mote %u is started!\n", TOS_NODE_ID);
  		}
     
    }
    else{
	//dbg for error
	dbg("radio", "Radio error!\n");
	call SplitControl.start();
    }    
  }
  
  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
    dbg("timer","Mote %u Stopped\n",TOS_NODE_ID);
    
  }
  
  event void StopTimer1.fired(){
   call SplitControl.stop();
  }


  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	/* This event is triggered every time the timer fires.
	 * When the timer fires, we send a request
	 * Fill this part...
	 */
    dbg("timer","Timer fired at %s.\n", sim_time_string());
    rec_id= 1; //REQ=1
	sendReq();
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	 
	if (&packet == buf && err== SUCCESS) {
      dbg("radio_send", "Packet sent by mote_%u correctly\n", TOS_NODE_ID);
      
      if((call PacketAcknowledgements.wasAcked(&packet)) == TRUE){ //Check if the ACK is received
      	dbg("radio_send", "ACK is received\n");
      	if(TOS_NODE_ID == 1){
      		call MilliTimer.stop();
      		dbg("timer", "timer stopped\n");
      	}
      	if(TOS_NODE_ID ==2) {
      	 call SplitControl.stop();
      	}
      	
      }else{
      	dbg("radio", "ACK is not received\n");
      }
      
    }
    else{
      dbgerror("radio_send", "Send done error!\n");
    }
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	if (len != sizeof(my_msg_t)) {return buf;}
    else {
      my_msg_t* mess = (my_msg_t*)payload;
      
      dbg("radio_rec", "Packet received at time %s\n", sim_time_string());
      dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( buf ));
      dbg("radio_pack", ">>>Pack \n");
      dbg_clear("radio_pack","\t\t Payload Received\n" );
      dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->msg_type);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	  dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->msg_counter);
	 
	 if(mess->msg_type == 2){
	 	call StopTimer1.startOneShot(250); //Timer used for stop radio of mote1 when receives RESP message
	 }
	 
     if(mess->msg_type== 1){
     	counter= mess->msg_counter;
     	rec_id= 2;
     	sendResp();
     	dbg("radio_send", "sendResp has been called\n");
     }
      return buf;
    }
    {
      dbgerror("radio_rec", "Receiving error \n");
    }
  }

  
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	double temp = (double)data;
	 
	 my_msg_t* mess = (my_msg_t*)(call Packet.getPayload(&packet, sizeof(my_msg_t)));
	 if (mess == NULL) {
		return;
	  }
	  
	  mess->msg_type= rec_id; //RESP TYPE
	  mess->msg_counter = counter;
	  mess->value=(uint16_t)temp;
	  dbg("radio_pack","Preparing the message... \n");
	  
	 if(call PacketAcknowledgements.requestAck(&packet) == SUCCESS){
	 	dbg("radio_ack","Set the ACK flag for the message...\n");
	 	if(call AMSend.send(1, &packet,sizeof(my_msg_t)) == SUCCESS){
	    	dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     	dbg_clear("radio_pack","\t Payload Sent\n" );
		 	dbg_clear("radio_pack", "\t\t type: RESP (coded as %hhu) \n ", mess->msg_type);
		 	dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);

  		}
	 }else{
		dbg("radio_ack","ACK Packet error\n");
	 }
 
	 
	}						
}

