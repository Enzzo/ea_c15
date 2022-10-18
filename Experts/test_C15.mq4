//+------------------------------------------------------------------+
//|                                                     test_C15.mq4 |
//|                        Copyright 2019, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2019, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

#include <trade.mqh>

CTrade trade();
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
//---
   //trade.SetExpertMagic(1234);
   EventSetTimer(3600);   
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
//---
   EventKillTimer();
}

void OnTimer(){
   double b[2];
   b[0] = iCustom(Symbol(), PERIOD_CURRENT, "C15/C15 1to1","", false, false, false, false, false, 0, 1);
   b[1] = iCustom(Symbol(), PERIOD_CURRENT, "C15/C15 1to1","", false, false, false, false, false, 1, 1);
      
   if(b[0] != EMPTY_VALUE){
      //trade.Buy(Symbol(), .01, 20, 90);
   }
   else if(b[1] != EMPTY_VALUE){
      //trade.Sell(Symbol(), .01, 20, 90);
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
   if(IsTesting()) OnTimer();
}
//+------------------------------------------------------------------+

string DTS(double d, int digits = 5){
   return DoubleToString(d, digits);
};

string ITS(int i){
   return IntegerToString(i);
};

void PrintArray(const double& ar[]){
   Print("------------------------------");
   for(int i = 0; i < ArraySize(ar); ++i){
      if(ar[i] != EMPTY_VALUE){
         Print("["+ITS(i)+"] "+DTS(ar[i]));
      }
   }   
}