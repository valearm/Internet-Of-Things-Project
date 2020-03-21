
#include "HomeChallenge1.h"

configuration HomeChallenge1AppC {}
implementation {
	//definizione dei componenti
  components MainC, HomeChallenge1C as App, LedsC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);//tipi di messaggio AM_RADIO_COUNT_MSG
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components new TimerMilliC() as Timer3;
  components ActiveMessageC;

  //colleghiamo i vari componenti
  App.Boot -> MainC.Boot;

  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.Timer1 -> Timer1;
  App.Timer2 -> Timer2;
  App.Timer3 -> Timer3;
  App.Packet -> AMSenderC;
}
