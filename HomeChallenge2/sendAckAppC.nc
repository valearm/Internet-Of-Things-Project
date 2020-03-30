/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  components new TimerMilliC() as t_one;//add the other components here
    components new TimerMilliC() as t_stop;
  components new FakeSensorC();
  components ActiveMessageC;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);


/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;
  
  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  //Radio Control
  //Interfaces to access package fields
   App.SplitControl -> ActiveMessageC;
   App.AMSend -> AMSenderC;
   App.Packet -> AMSenderC;
   App.Receive -> AMReceiverC;
   App.PacketAcknowledgements-> AMSenderC;
  
  //Timer interface
   App.MilliTimer -> t_one;
   App.StopTimer1 -> t_stop;
   
  //Fake Sensor read
  App.Read -> FakeSensorC;

}

