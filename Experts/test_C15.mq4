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

enum ENUM_EXIT_LEVEL{
   fixed,      // FIXED
   indicator   // BY INDICATOR LEVELS
};

enum ENUM_LOT_TYPE{
   fixed_lot,      // FIXED LOT
   auto_lot        // AUTO LOT
};

input int MAGIC = 282083;
input string INDICATOR_ENTRY = "C15/C15 3to1";
input bool BACKGROUND = true;
input string INDICATOR_BACKGROUND = "C15/C15 Trend";
input ENUM_LOT_TYPE LOT_TYPE = fixed_lot;
input double RISK = 1.0;
input double VOLUME = .01;
input ENUM_EXIT_LEVEL EXIT_LEVEL = fixed;  
input int SL = 20;
input int TP = 50;
input string c01 = "-------------------------------------- BREAKEVEN ---------------------------------------";
input bool BREAKEVEN = true;
input int BREAKEVEN_POINTS = 20;
input string c02 = "----------------------------------------- TRAL -----------------------------------------";
input bool TRAL = true;
input int STOP = 20;
input int STEP = 10;

CTrade trade();
ushort mtp = (Digits() == 3 || Digits() == 5)?10:1;

// ID - идентификатор сигнала (время открытия свечи текущего таймфрейма)
// sent - флаг. выставлен ордер, или нет. Если выставлен, то true. больше по этому сигналу не работаем
// direction - направление сигнала
struct Signal{
   long ID;
   int direction;
   bool sent;
};

class OrderParameters{
public:
   OrderParameters() = delete;
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit(){
//---
   trade.SetExpertMagic(MAGIC);
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
//---
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
//---
   //if(IsTesting()) OnTimer();
   
   static Signal signal = {-1, -1, true};
   
   GetSignal(signal);
   int last_position = GetLastPosition();   
   
   if(!signal.sent){
      double sl, tp;
      ExtractPrices(sl, tp);
      bool send = false;
      
      if(signal.direction == OP_BUY){
         send = true;
         int sl_pts = (int)((Ask - sl) / Point / mtp);
      }
      if(signal.direction == OP_SELL){
         send = true;
         int sl_pts = (int)((sl - Bid) / Point / mtp);
      }
      if(send)signal.sent = trade.Deal(signal.direction, Symbol(), .01, SL, TP);
   }
   
   if(BREAKEVEN)  Breakeven();
   if(TRAL)       trade.TralPointsGeneral(STOP, STEP, BREAKEVEN);
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
//+------------------------------------------------------------------+
//| GetSignal()                                             |
//+------------------------------------------------------------------+
void GetSignal(Signal& signal){
   
   long id = iTime(Symbol(), PERIOD_CURRENT, 1);
   if(signal.ID == id) return;   
   
   double b = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_ENTRY,"", false, false, false, false, false, 0, 1);
   double s = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_ENTRY,"", false, false, false, false, false, 1, 1);
   
   double buf0 = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_BACKGROUND, 0, 0);
   double buf1 = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_BACKGROUND, 1, 0);
   
   bool bullish_background = buf0 > buf1;
   
   signal.direction = (b != EMPTY_VALUE && (bullish_background || !BACKGROUND))?0:(s != EMPTY_VALUE && (!bullish_background || !BACKGROUND))?1:-1;
   //signal.direction = (b != EMPTY_VALUE)?0:(s != EMPTY_VALUE)?1:-1;

   
   if(signal.direction != -1){      
      signal.ID = id;
      signal.sent = false;
      // PrintSignal(signal); 
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

//void PrintSignal(const Signal& signal){
//   Comment(signal.ID+" "+signal.direction+" "+signal.sent);
//}

//void PrintBuffers(){
//   
//   string comment;
//   for(int i = 0; i < 7; ++i){
//      double b = iCustom(Symbol(), PERIOD_CURRENT, INDICATOR_BACKGROUND,"", false, false, false, false, false, i, 1);
//      comment += DTS(b)+"\n";
//      Print("["+i+"] "+DTS(b));
//   }
//   Comment(comment);
//}

void ExtractPrices(double& sl, double& tp){
   int objects_total = ObjectsTotal(ChartID());
   bool t = false;
   bool s = false;
   
   for(int i = objects_total-1; i >= 0; --i){
      if(s && t) break;
      string name = ObjectName(ChartID(), i);
      if(!t && StringFind(name, ":tp2") != -1){
         string text = ObjectGetString(ChartID(), name, OBJPROP_TEXT);
         tp = StringToDouble(StringSubstr(text, 5));
         t = true;
      }
      if(!s && StringFind(name, ":sl2") != -1){
         string text = ObjectGetString(ChartID(), name, OBJPROP_TEXT);
         sl = StringToDouble(StringSubstr(text, 5));
         s = true;
      }
   }
}

void Breakeven(){
   int total = OrdersTotal();
   for(int i = total-1; i >= 0; --i){
      if(!OrderSelect(i, SELECT_BY_POS)){
         Print(__FUNCTION__,"  ",GetLastError());
         return;
      }
      if(OrderMagicNumber()== MAGIC){
         if(OrderType() == OP_BUY){
            if(OrderStopLoss() < OrderOpenPrice() && Bid > OrderOpenPrice() + BREAKEVEN_POINTS * Point * mtp){
               bool x = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), OrderExpiration());
            }
         }
         else if(OrderType() == OP_SELL){
            if((OrderOpenPrice() < OrderStopLoss() || OrderStopLoss() == 0.0) && Ask < OrderOpenPrice() - BREAKEVEN_POINTS * Point * mtp){
               bool x = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), OrderExpiration());
            }
         }
      }
   }   
}
//
//void Tral(int stop, int step){
//   int total = OrdersTotal();
//   for(int i = total-1; i >= 0; --i){
//      if(!OrderSelect(i, SELECT_BY_POS)){
//         Print(__FUNCTION__,"  ",GetLastError());
//         return;
//      }
//      if(OrderMagicNumber()== MAGIC){
//         int      ticket  = OrderTicket();
//         int      type    = OrderType();
//         double   sl      = OrderStopLoss();         
//         double   tp      = OrderTakeProfit();
//         double   open    = OrderOpenPrice();
//         datetime expir   = OrderExpiration();
//         
//         if(type == OP_BUY){
//            if(sl >= open && Bid > sl + (stop + step) * Point * mtp){
//               //double sl_mod = sl + step * Point * mtp;
//               //bool x = OrderModify(ticket, open, sl_mod, tp, expir);
//               trade.TralPoints(ticket, step, stop);
//            }
//         }
//         else if(type == OP_SELL){
//            if((open >= sl && sl != 0.0) && Ask < sl - (stop + step) * Point * mtp){
//               double sl_mod = sl - step * Point * mtp;
//               bool x = OrderModify(ticket, open, sl_mod, tp, expir);
//            }
//         }
//      }
//   } 
//}