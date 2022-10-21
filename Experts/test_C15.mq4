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

input int MAGIC = 282083;
input string INDICATOR_ENTRY = "C15/C15 3to1";
input string INDICATOR_BACKGROUND = "C15/C15 Trend";
input double RISK = 1.0;
input double VOLUME = .01;
input int SL = 20;
input int TP = 50;

CTrade trade();

// ID - идентификатор сигнала (время открытия свечи текущего таймфрейма)
// sent - флаг. выставлен ордер, или нет. Если выставлен, то true. больше по этому сигналу не работаем
// direction - направление сигнала
struct Signal{
   long ID;
   int direction;
   bool sent;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
//---
   //trade.SetExpertMagic(1234);
   EventSetTimer(3600);   
   trade.SetExpertMagic(MAGIC);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
//---
   EventKillTimer();
   Comment("");
}

void OnTimer(){

}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
   //if(IsTesting()) OnTimer();
   
   static Signal signal;
   
   GetSignal(signal);
   int last_position = GetLastPosition();
   
   // Comment(ITS(signal)+" "+(ITS(last_position)));
   
   // if(signal == -1 || signal == last_position) return;
   
   if(!signal.sent){
      
      if(signal.direction == 0){
         double sl, tp;
         ExtractPrices(sl, tp);
         // trade.Buy(Symbol(), AutoLot(RISK, SL), SL, TP);
         trade.Buy(Symbol(), 0.01, sl, tp);
         signal.sent = true;
      }
      else if(signal.direction == 1){
      double sl, tp;
         ExtractPrices(sl, tp);
         // trade.Sell(Symbol(), AutoLot(RISK, SL), SL, TP);
         trade.Sell(Symbol(), 0.01, sl, tp);
         signal.sent = true;
      }
   }
}
//+------------------------------------------------------------------+

string DTS(double d, int digits = 5){
   return DoubleToString(d, digits);
};

string ITS(int i){
   return IntegerToString(i);
};

//+------------------------------------------------------------------+
//r - риск %, p - пункты до стоплосса
double AutoLot(const double r, const int p){
   double l = MarketInfo(Symbol(), MODE_MINLOT);
   
   l = NormalizeDouble((AccountBalance()/100*r/(p*MarketInfo(Symbol(), MODE_TICKVALUE))), 2);
   
   if(l > MarketInfo(Symbol(), MODE_MAXLOT))l = MarketInfo(Symbol(), MODE_MAXLOT);
   if(l < MarketInfo(Symbol(), MODE_MINLOT))l = MarketInfo(Symbol(), MODE_MINLOT);
   return l;
}

void GetSignal(Signal& signal){
   
   // long id = StringToInteger(TimeToString(iTime(Symbol(), PERIOD_CURRENT, 1)));
   long id = iTime(Symbol(), PERIOD_CURRENT, 1);
   if(signal.ID == id) return;
      
   double b = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_ENTRY,"", false, false, false, false, false, 0, 1);
   double s = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_ENTRY,"", false, false, false, false, false, 1, 1);
   
   double buf0 = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_BACKGROUND, 0, 1);
   double buf1 = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_BACKGROUND, 1, 1);
   
   bool bullis_background = buf0 > buf1;
   
   signal.direction = (b != EMPTY_VALUE && bullis_background)?0:(s != EMPTY_VALUE && !bullis_background)?1:-1;
   
   if(signal.direction != -1){      
      signal.ID = id;
      signal.sent = false;
   }
}

// Check last open position
int GetLastPosition(){
   int total = OrdersTotal();
   for(int i = total-1; i >= 0; --i){
      if(!OrderSelect(i, SELECT_BY_POS)){
         Print(__FUNCTION__,"  ",GetLastError());
         return -1;
      }
      if(OrderMagicNumber()== MAGIC){ return OrderType();}
   }
   return -1;
}

void PrintArray(const double& ar[]){
   Print("------------------------------");
   for(int i = 0; i < ArraySize(ar); ++i){
      if(ar[i] != EMPTY_VALUE){
         Print("["+ITS(i)+"] "+DTS(ar[i]));
      }
   }   
}

void PrintSignal(const Signal& signal){
   Comment(signal.ID+" "+signal.direction+" "+signal.sent);
}

void PrintBuffers(){
   
   string comment;
   for(int i = 0; i < 7; ++i){
      double b = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_BACKGROUND,"", false, false, false, false, false, i, 1);
      comment += DTS(b)+"\n";
      Print("["+i+"] "+DTS(b));
   }
   Comment(comment);
}

void ExtractPrices(double& sl, double& tp){
   int objects_total = ObjectsTotal(ChartID());
   bool t = false;
   bool s = false;
   
   for(int i = objects_total-1; i >= 0; --i){
      if(s && t) break;
      string name = ObjectName(ChartID(), i);
      if(!t && StringFind(name, ":tp2") != -1){
         string text = ObjectGetString(ChartID(), name, OBJPROP_TEXT);
         tp = StringSubstr(text, 5);
         t = true;
      }
      if(!s && StringFind(name, ":sl2") != -1){
         string text = ObjectGetString(ChartID(), name, OBJPROP_TEXT);
         sl = StringSubstr(text, 5);
         s = true;
      }
   }
}