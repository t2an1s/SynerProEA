// SynPropEA1.mq5
#property copyright "t2an1s"
#property link      "https://github.com/t2an1s/SynerProEA"
#property version   "1.04" // Updated version
#property strict
#property description "Master EA for Synergy Strategy - Prop Account"

#include "SynPropEA1_Dashboard.mqh" 

// --- Global Variables & Inputs ---
// File Names
input string InpCommonFileName    = "SynerProEA_Commands.csv";
input string InpSlaveStatusFile   = "EA2_Status.txt";

// Trading Parameters
input double InpLotSize           = 0.01;
input bool   InpUseRiskPercent    = true;
input double InpRiskPercent       = 0.3;
input int    InpSlippage          = 3; 
input int    InpMagicNumber       = 12345;
input double InpRiskRewardRatio   = 2.0; 
input double InpStopLossBufferPips  = 2.0; 
input bool   InpAllowTrades       = true; 
input int    InpPyramidingMaxOrders = 1; // Max orders for pyramiding (1 = no pyramiding)


// Challenge Parameters (Static Limits for Prop Account)
input double InpChallengeCost     = 700.0; 
input int    InpChallengeStages   = 1;     
input double InpStageTargetProfitDollars = 1000.0; 
input double InpMaxAccountDDLimitDollars = 4000.0; 
input double InpDailyDDLimitDollars    = 2000.0; 
input double InpPropStartBalanceOverride = 0.0;  
input int    InpMinTradingDaysTotal_Prop = 5;    

// Session Filter Inputs
input string InpMondaySession1    = "08:00-16:00"; input string InpMondaySession2    = "";
input string InpTuesdaySession1   = "08:00-16:00"; input string InpTuesdaySession2   = "";
input string InpWednesdaySession1 = "08:00-16:00"; input string InpWednesdaySession2 = "";
input string InpThursdaySession1  = "08:00-16:00"; input string InpThursdaySession2  = "";
input string InpFridaySession1    = "08:00-15:00"; input string InpFridaySession2    = "";
input string InpSaturdaySession1  = "";            input string InpSaturdaySession2  = "";
input string InpSundaySession1    = "";            input string InpSundaySession2    = "";
input string InpBrokerTimeZoneOffset = "+2";

// Heikin-Ashi Bias
input ENUM_TIMEFRAMES InpHA_Timeframe    = PERIOD_H1;
input int             InpHA_MAPeriod     = 10; 
input int             InpHA_SignalMAPeriod = 5; 
input bool            InpDisableHABias   = false;
input double          InpHA_BiasThreshold = 0.0; 

// ADX Gate
input int    InpADX_Period        = 14;
input bool   InpUseDynamicADX     = true;
input double InpStaticADXThreshold= 20.0; 
input int    InpDynamicADXMAPeriod= 20;
input double InpDynamicADXMultiplier = 1.0; 
input double InpADXMinThreshold   = 15.0;

// --- Synergy Score Inputs ---
// M5
input int    InpSyn_M5_RSI_Period    = 14;     input double InpSyn_M5_RSI_Weight       = 1.0;
input int    InpSyn_M5_EMA_Fast_Period = 10;     input int    InpSyn_M5_EMA_Slow_Period  = 100; input double InpSyn_M5_Trend_Weight   = 1.0;
input int    InpSyn_M5_MACD_Fast     = 12;     input int    InpSyn_M5_MACD_Slow      = 26;  input double InpSyn_M5_MACDV_Weight   = 1.0;
// M15
input int    InpSyn_M15_RSI_Period   = 14;     input double InpSyn_M15_RSI_Weight      = 1.0;
input int    InpSyn_M15_EMA_Fast_Period= 50;     input int    InpSyn_M15_EMA_Slow_Period = 200; input double InpSyn_M15_Trend_Weight  = 1.0;
input int    InpSyn_M15_MACD_Fast    = 12;     input int    InpSyn_M15_MACD_Slow     = 26;  input double InpSyn_M15_MACDV_Weight  = 1.0;
// H1
input int    InpSyn_H1_RSI_Period    = 14;     input double InpSyn_H1_RSI_Weight       = 1.0;
input int    InpSyn_H1_EMA_Fast_Period = 50;     input int    InpSyn_H1_EMA_Slow_Period  = 200; input double InpSyn_H1_Trend_Weight   = 1.0;
input int    InpSyn_H1_MACD_Fast     = 12;     input int    InpSyn_H1_MACD_Slow      = 26;  input double InpSyn_H1_MACDV_Weight   = 1.0;

input bool   InpDisableSynergyScore = false;

// Pivots
input int    InpPivotLookbackBars = 50; 
input int    InpPivotLeftBars     = 6;  
input int    InpPivotRightBars    = 6;  

// Visual Toggles
input bool   InpShowPivotVisuals    = true;
input color  InpPivotUpColor        = clrGreen; 
input color  InpPivotDownColor      = clrRed;   
input bool   InpShowMarketBiasVisual= true;
input color  InpMarketBiasUpColor   = C'173,216,230'; 
input color  InpMarketBiasDownColor = C'255,192,203'; 


// --- Internal Global Variables ---
int    h_adx_main; 

double val_HA_Bias_Oscillator;
double prev_HA_Bias_Oscillator_Value; 
bool   biasChangedToBullish_MQL;
bool   biasChangedToBearish_MQL;

double val_ADX_Main, val_ADX_Plus, val_ADX_Minus;
double val_ADX_Threshold;
double val_SynergyScore_M5, val_SynergyScore_M15, val_SynergyScore_H1;
double val_TotalSynergyScore;

PivotPoint recent_pivot_high; 
PivotPoint recent_pivot_low;  
PivotPoint g_identified_pivots_high[]; 
PivotPoint g_identified_pivots_low[];  

long   broker_time_gmt_offset_seconds;
bool   is_session_active;
datetime PrevBarTime; 
string g_ea_version_str = "1.04"; 

double   g_initial_challenge_balance_prop; 
double   g_prop_balance_at_day_start;
double   g_prop_highest_equity_peak;
int      g_prop_current_trading_days;
datetime g_last_day_for_daily_reset; 
datetime g_unique_trading_day_dates[]; 
int      g_min_bars_needed_for_ea = 200; 
double   g_point_value; 
int      g_digits_value; 
int      g_ea_open_positions_count = 0;    // Count of positions by this EA on this symbol
ENUM_ORDER_TYPE g_ea_open_positions_type = WRONG_VALUE; // Direction of existing EA positions

//+------------------------------------------------------------------+
void UpdateEAOpenPositionsState()
  {
   g_ea_open_positions_count = 0;
   g_ea_open_positions_type = WRONG_VALUE; // Reset
   int total_positions = PositionsTotal();

   for(int i = total_positions - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            g_ea_open_positions_count++;
            if(g_ea_open_positions_type == WRONG_VALUE) // Store type of the first found position
              {
               g_ea_open_positions_type = (ENUM_ORDER_TYPE)PositionGetInteger(POSITION_TYPE);
              }
           }
        }
     }
    // PrintFormat("UpdateEAOpenPositionsState: Count=%d, Type=%s", g_ea_open_positions_count, EnumToString(g_ea_open_positions_type));
  }


//+------------------------------------------------------------------+
double GetPipToPointsMultiplier()
  {
   string sym = _Symbol;
   bool isForexOrMetal = (StringFind(sym, "USD") >= 0 || StringFind(sym, "EUR") >= 0 || StringFind(sym, "GBP") >= 0 ||
                         StringFind(sym, "JPY") >= 0 || StringFind(sym, "AUD") >= 0 || StringFind(sym, "NZD") >= 0 ||
                         StringFind(sym, "CAD") >= 0 || StringFind(sym, "CHF") >= 0 || StringFind(sym, "XAU") >= 0 ||
                         StringFind(sym, "XAG") >= 0);

   if(isForexOrMetal && (g_digits_value == 5 || g_digits_value == 3))
     {
      return 10.0;
     }
   return 1.0;
  }

//+------------------------------------------------------------------+
void CalculateGMTOffset()
  {
   string offset_str = InpBrokerTimeZoneOffset;
   StringReplace(offset_str, "GMT", "");
   StringReplace(offset_str, " ", ""); 
   broker_time_gmt_offset_seconds = (long)StringToInteger(offset_str) * 3600;
   Print("Broker GMT Offset Seconds: ", broker_time_gmt_offset_seconds);
  }

//+------------------------------------------------------------------+
bool IsInTradingSession()
  {
   datetime current_broker_dt = TimeCurrent(); 
   MqlDateTime current_broker_time_struct;
   TimeToStruct(current_broker_dt, current_broker_time_struct);

   datetime current_gmt_timestamp = (datetime)(current_broker_dt - broker_time_gmt_offset_seconds); 
   MqlDateTime gmt_time_struct;
   TimeToStruct(current_gmt_timestamp, gmt_time_struct);

   int day_of_week = gmt_time_struct.day_of_week; 
   int current_hour_gmt = gmt_time_struct.hour;
   int current_min_gmt = gmt_time_struct.min;

   string session1_str = "", session2_str = "";

   switch(day_of_week)
     {
      case 0: session1_str = InpSundaySession1;    session2_str = InpSundaySession2;    break;
      case 1: session1_str = InpMondaySession1;    session2_str = InpMondaySession2;    break;
      case 2: session1_str = InpTuesdaySession1;   session2_str = InpTuesdaySession2;   break;
      case 3: session1_str = InpWednesdaySession1; session2_str = InpWednesdaySession2; break;
      case 4: session1_str = InpThursdaySession1;  session2_str = InpThursdaySession2;  break;
      case 5: session1_str = InpFridaySession1;    session2_str = InpFridaySession2;    break;
      case 6: session1_str = InpSaturdaySession1;  session2_str = InpSaturdaySession2;  break;
     }

   bool in_session1 = false;
   bool in_session2 = false;

   if(session1_str != "" && StringFind(session1_str, "-") > 0)
     {
      string times[]; StringSplit(session1_str, '-', times);
      if(ArraySize(times) == 2)
        {
         string start_hm[]; StringSplit(times[0], ':', start_hm);
         string end_hm[];   StringSplit(times[1], ':', end_hm);
         if(ArraySize(start_hm) == 2 && ArraySize(end_hm) == 2)
           {
            int start_h = (int)StringToInteger(start_hm[0]); int start_m = (int)StringToInteger(start_hm[1]);
            int end_h   = (int)StringToInteger(end_hm[0]);   int end_m   = (int)StringToInteger(end_hm[1]);
            int current_time_in_mins = current_hour_gmt * 60 + current_min_gmt;
            int start_time_in_mins   = start_h * 60 + start_m;
            int end_time_in_mins     = end_h * 60 + end_m;

            if(end_time_in_mins < start_time_in_mins) 
              {
               if(current_time_in_mins >= start_time_in_mins || current_time_in_mins < end_time_in_mins)
                  in_session1 = true;
              }
            else 
              {
               if(current_time_in_mins >= start_time_in_mins && current_time_in_mins < end_time_in_mins)
                  in_session1 = true;
              }
           }
        }
     }

   if(session2_str != "" && StringFind(session2_str, "-") > 0)
     {
      string times[]; StringSplit(session2_str, '-', times);
      if(ArraySize(times) == 2)
        {
         string start_hm[]; StringSplit(times[0], ':', start_hm);
         string end_hm[];   StringSplit(times[1], ':', end_hm);
         if(ArraySize(start_hm) == 2 && ArraySize(end_hm) == 2)
           {
            int start_h = (int)StringToInteger(start_hm[0]); int start_m = (int)StringToInteger(start_hm[1]);
            int end_h   = (int)StringToInteger(end_hm[0]);   int end_m   = (int)StringToInteger(end_hm[1]);
            int current_time_in_mins = current_hour_gmt * 60 + current_min_gmt;
            int start_time_in_mins   = start_h * 60 + start_m;
            int end_time_in_mins     = end_h * 60 + end_m;

            if(end_time_in_mins < start_time_in_mins) 
              {
               if(current_time_in_mins >= start_time_in_mins || current_time_in_mins < end_time_in_mins)
                  in_session2 = true;
              }
            else 
              {
               if(current_time_in_mins >= start_time_in_mins && current_time_in_mins < end_time_in_mins)
                  in_session2 = true;
              }
           }
        }
     }
   if((session1_str == "" && session2_str == "") || in_session1 || in_session2)
     {
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
void AddUniqueTradingDay(datetime trade_event_time)
  {
   MqlDateTime dt_struct;
   TimeToStruct(trade_event_time, dt_struct);
   dt_struct.hour = 0; dt_struct.min = 0; dt_struct.sec = 0;
   datetime date_only = StructToTime(dt_struct); 

   bool found = false;
   for(int i = 0; i < ArraySize(g_unique_trading_day_dates); i++)
     {
      if(g_unique_trading_day_dates[i] == date_only)
        {
         found = true;
         break;
        }
     }
   if(!found)
     {
      int arr_size = ArraySize(g_unique_trading_day_dates);
      ArrayResize(g_unique_trading_day_dates, arr_size + 1);
      g_unique_trading_day_dates[arr_size] = date_only;
      g_prop_current_trading_days = ArraySize(g_unique_trading_day_dates);
      PrintFormat("New unique trading day added: %s. Total unique trading days: %d", TimeToString(date_only, TIME_DATE), g_prop_current_trading_days);
     }
  }
  
//+------------------------------------------------------------------+
void IdentifyPivotsForVisuals() 
  {
   ArrayFree(g_identified_pivots_high);
   ArrayFree(g_identified_pivots_low);

   int rates_total = (int)Bars(_Symbol, _Period);
   int lookback_visual = InpPivotLookbackBars; 
   int left_bars_visual = InpPivotLeftBars;
   int right_bars_visual = InpPivotRightBars;

   if(rates_total < lookback_visual + right_bars_visual + 1 || rates_total < left_bars_visual + right_bars_visual + 1) return;

   double high[], low[];
   datetime times[];
   
   int bars_to_copy = lookback_visual + left_bars_visual + right_bars_visual + 5; 
   if(CopyHigh(_Symbol, _Period, 0, bars_to_copy, high) < bars_to_copy ||
      CopyLow(_Symbol, _Period, 0, bars_to_copy, low) < bars_to_copy ||
      CopyTime(_Symbol, _Period, 0, bars_to_copy, times) < bars_to_copy)
     {
      Print("Error copying price/time data for visual pivots.");
      return;
     }
   ArraySetAsSeries(high, true); 
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(times, true);

   for(int i = right_bars_visual; i < lookback_visual + right_bars_visual ; i++) 
     {
      if (i + left_bars_visual >= ArraySize(high) || i - right_bars_visual < 0) continue; 

      bool is_pivot_high = true;
      double current_high_val = high[i];
      for(int j = i - left_bars_visual; j <= i + right_bars_visual; j++)
        {
         if(j == i) continue;
         if(j < 0 || j >= ArraySize(high)) {is_pivot_high = false; break;} 
         if(high[j] > current_high_val) { is_pivot_high = false; break; }
        }
      if(is_pivot_high)
        {
         int current_size = ArraySize(g_identified_pivots_high);
         ArrayResize(g_identified_pivots_high, current_size + 1);
         g_identified_pivots_high[current_size].time = times[i];
         g_identified_pivots_high[current_size].price = high[i];
        }

      bool is_pivot_low = true;
      double current_low_val = low[i];
      for(int j = i - left_bars_visual; j <= i + right_bars_visual; j++)
        {
         if(j == i) continue;
         if(j < 0 || j >= ArraySize(low)) {is_pivot_low = false; break;} 
         if(low[j] < current_low_val) { is_pivot_low = false; break; }
        }
      if(is_pivot_low)
        {
         int current_size = ArraySize(g_identified_pivots_low);
         ArrayResize(g_identified_pivots_low, current_size + 1);
         g_identified_pivots_low[current_size].time = times[i];
         g_identified_pivots_low[current_size].price = low[i];
        }
     }
  }

//+------------------------------------------------------------------+
double CalculateLotSize(double stop_loss_distance_points) 
  {
   double lot_size = InpLotSize; 

   if(InpUseRiskPercent)
     {
      if(stop_loss_distance_points <= 0)
        {
         Print("CalculateLotSize: Cannot calculate risk-based lot size. Stop loss distance is zero or negative: ", stop_loss_distance_points);
         return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); 
        }

      double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_amount = account_balance * (InpRiskPercent / 100.0);
      
      double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE); 
      double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);   
      
      if(tick_size == 0 || g_point_value == 0)
        {
         Print("CalculateLotSize: Tick size or point size is zero for symbol ", _Symbol);
         return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); 
        }
        
      double value_per_point_one_lot = (tick_value / tick_size) * g_point_value;
      
      if(value_per_point_one_lot <= 0)
        {
         Print("CalculateLotSize: Calculated value_per_point_one_lot is zero or negative: ", value_per_point_one_lot, " (TickValue: ", tick_value, ", TickSize: ", tick_size, ", PointSize: ", g_point_value,")");
         return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        }

      double loss_per_lot_at_sl = stop_loss_distance_points * value_per_point_one_lot;

      if(loss_per_lot_at_sl <= 0)
        {
         Print("CalculateLotSize: Calculated loss_per_lot_at_sl is zero or negative: ", loss_per_lot_at_sl);
         return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
        }
        
      lot_size = risk_amount / loss_per_lot_at_sl;
      PrintFormat("CalculateLotSize (Risk Based): Balance=%.2f, RiskPct=%.2f%%, RiskAmt=%.2f, SLDistPoints=%.1f, ValPerPoint1Lot=%.5f, LossPerLotAtSL=%.2f, RawLot=%.5f",
                  account_balance, InpRiskPercent, risk_amount, stop_loss_distance_points, value_per_point_one_lot, loss_per_lot_at_sl, lot_size);
     }
   else 
     {
        PrintFormat("CalculateLotSize (Fixed): Lot=%.2f", lot_size);
     }

   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot_size = MathMax(lot_size, min_lot); 
   lot_size = MathMin(lot_size, max_lot); 

   if (lot_step > 0)
     {
      lot_size = MathRound(lot_size / lot_step) * lot_step;
      lot_size = MathMax(lot_size, min_lot); 
      lot_size = MathMin(lot_size, max_lot); 
     }
   
   if (lot_size < min_lot && min_lot > 0) lot_size = min_lot;
   if (lot_size == 0 && min_lot == 0 && lot_step > 0) lot_size = lot_step; 
   else if (lot_size == 0 && min_lot > 0) lot_size = min_lot;


   PrintFormat("CalculateLotSize: Final Normalized Lot=%.2f (Min:%.2f, Max:%.2f, Step:%.2f)", lot_size, min_lot, max_lot, lot_step);
   return lot_size;
  }

//+------------------------------------------------------------------+
double CalculateStopLoss(int signal_type, double entry_price) 
  {
   double sl_price = 0.0;
   double pip_to_points_multiplier = GetPipToPointsMultiplier();
   double buffer_points_price_units = InpStopLossBufferPips * pip_to_points_multiplier * g_point_value; 

   if(signal_type == 1) // BUY
     {
      if(recent_pivot_low.price > 0 && recent_pivot_low.price < entry_price)
        {
         sl_price = recent_pivot_low.price - buffer_points_price_units;
         PrintFormat("SL Calc (BUY): Using Pivot Low %.5f (Time: %s), Buffer %.5f. SL: %.5f", 
                     recent_pivot_low.price, TimeToString(recent_pivot_low.time), buffer_points_price_units, sl_price);
        }
      else
        {
         PrintFormat("SL Calc (BUY): Pivot Low not valid (Price: %.5f, Time: %s) or not below entry (%.5f). No SL calculated.",
                     recent_pivot_low.price, TimeToString(recent_pivot_low.time), entry_price);
         return 0.0; 
        }
     }
   else if(signal_type == -1) // SELL
     {
      if(recent_pivot_high.price > 0 && recent_pivot_high.price > entry_price)
        {
         sl_price = recent_pivot_high.price + buffer_points_price_units;
         PrintFormat("SL Calc (SELL): Using Pivot High %.5f (Time: %s), Buffer %.5f. SL: %.5f", 
                     recent_pivot_high.price, TimeToString(recent_pivot_high.time), buffer_points_price_units, sl_price);
        }
      else
        {
         PrintFormat("SL Calc (SELL): Pivot High not valid (Price: %.5f, Time: %s) or not above entry (%.5f). No SL calculated.",
                     recent_pivot_high.price, TimeToString(recent_pivot_high.time), entry_price);
         return 0.0; 
        }
     }
   else 
     {
      Print("SL Calc: Invalid signal_type provided: ", signal_type);
      return 0.0;
     }

   if(sl_price != 0.0)
     {
      double min_sl_distance_points = 1.0 * pip_to_points_multiplier; 
      double current_sl_distance_points = MathAbs(entry_price - sl_price) / g_point_value;

      if (g_point_value > 0 && current_sl_distance_points < min_sl_distance_points) { // Ensure g_point_value is valid
          PrintFormat("SL Calc (%s): Calculated SL %.5f (Dist: %.1f pts) is too close to entry %.5f (MinDist: %.1f pts). Invalidating SL.", 
                      (signal_type == 1 ? "BUY" : "SELL"), sl_price, current_sl_distance_points, entry_price, min_sl_distance_points);
          return 0.0; 
      }
      sl_price = NormalizeDouble(sl_price, g_digits_value);
     }
   return sl_price;
  }

//+------------------------------------------------------------------+
double CalculateTakeProfit(int signal_type, double entry_price, double stop_loss_price)
  {
   if(stop_loss_price == 0.0 || entry_price == 0.0 || InpRiskRewardRatio <= 0)
     {
      Print("TP Calc: SL (%.5f) or Entry (%.5f) is 0.0 or R:R ratio (%.2f) is invalid. Cannot calculate TP.", stop_loss_price, entry_price, InpRiskRewardRatio);
      return 0.0;
     }

   double sl_distance_price = MathAbs(entry_price - stop_loss_price);
   if(g_point_value > 0 && sl_distance_price <= g_point_value) 
     {
       PrintFormat("TP Calc: SL distance (%.*f) is too small (<= 1 point). Cannot calculate TP.", g_digits_value, sl_distance_price);
       return 0.0;
     }
     
   double tp_distance_price = sl_distance_price * InpRiskRewardRatio;
   double tp_price = 0.0;

   if(signal_type == 1) // BUY
     {
      tp_price = entry_price + tp_distance_price;
     }
   else if(signal_type == -1) // SELL
     {
      tp_price = entry_price - tp_distance_price;
     }
   else
     {
      Print("TP Calc: Invalid signal_type provided: ", signal_type);
      return 0.0;
     }

   if(tp_price != 0.0)
     {
      tp_price = NormalizeDouble(tp_price, g_digits_value);
      PrintFormat("TP Calc (%s): Entry %.5f, SL %.5f, SL Dist %.5f, RR %.2f, TP Dist %.5f, TP: %.5f",
                  (signal_type == 1 ? "BUY" : "SELL"), entry_price, stop_loss_price, sl_distance_price, InpRiskRewardRatio, tp_distance_price, tp_price);
     }
   return tp_price;
  }

//+------------------------------------------------------------------+
bool OpenTrade(int signal_type, double lot_size, double sl_price, double tp_price, string comment)
  {
   // Decision to trade (pyramiding, max orders, direction) is now handled in OnTick before calling this.
   // This function focuses on the mechanics of sending the order.

   MqlTradeRequest request;
   MqlTradeResult  result;
   ZeroMemory(request);
   ZeroMemory(result);

   request.action = TRADE_ACTION_DEAL;
   request.symbol = _Symbol;
   request.volume = lot_size;
   request.magic  = InpMagicNumber;
   request.comment = comment;
   request.deviation = InpSlippage; 
   request.type_filling = ORDER_FILLING_FOK; 

   if(signal_type == 1) // BUY
     {
      request.type = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
     }
   else if(signal_type == -1) // SELL
     {
      request.type = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
     }
   else
     {
      Print("OpenTrade: Invalid signal_type provided: ", signal_type);
      return false;
     }

   if(sl_price > 0) request.sl = NormalizeDouble(sl_price, g_digits_value);
   if(tp_price > 0) request.tp = NormalizeDouble(tp_price, g_digits_value);

   double current_price_for_check = request.price; 
   double min_stop_level_points = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double min_stop_level_price_units = min_stop_level_points * g_point_value;

   if(request.sl != 0 && g_point_value > 0) // Check g_point_value to prevent division by zero if not initialized
     {
      if(request.type == ORDER_TYPE_BUY && (current_price_for_check - request.sl) < min_stop_level_price_units)
        {
         PrintFormat("OpenTrade Validation (BUY): SL %.5f is too close to Ask %.5f. Min Stop Level: %.1f points (%.5f). Trade aborted.",
                     request.sl, current_price_for_check, min_stop_level_points, min_stop_level_price_units);
         return false; 
        }
      if(request.type == ORDER_TYPE_SELL && (request.sl - current_price_for_check) < min_stop_level_price_units)
        {
         PrintFormat("OpenTrade Validation (SELL): SL %.5f is too close to Bid %.5f. Min Stop Level: %.1f points (%.5f). Trade aborted.",
                     request.sl, current_price_for_check, min_stop_level_points, min_stop_level_price_units);
         return false;
        }
     }
   
   PrintFormat("Attempting to open %s trade: Lot=%.2f, Entry=%.5f, SL=%.5f, TP=%.5f, Comment='%s'",
               (request.type == ORDER_TYPE_BUY ? "BUY" : "SELL"), lot_size, request.price, request.sl, request.tp, comment);

   if(!OrderSend(request, result))
     {
      PrintFormat("OrderSend failed. Error code: %d. Retcode: %d. Message: %s",
                  GetLastError(), result.retcode, result.comment);
      return false;
     }

   PrintFormat("OrderSend successful. Order ticket: %d. Deal ticket: %d. Price: %.5f. Volume: %.2f. Comment: %s",
               result.order, result.deal, result.price, result.volume, result.comment);
   
   if(result.retcode == TRADE_RETCODE_DONE || result.retcode == TRADE_RETCODE_PLACED)
     {
      AddUniqueTradingDay(TimeCurrent()); 
      // g_ea_open_positions_count is updated by UpdateEAOpenPositionsState() at start of OnTick
      return true;
     }
   return false;
  }
  
//+------------------------------------------------------------------+
int OnInit()
  {
   PrevBarTime = 0; 
   CalculateGMTOffset();
   
   g_point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   g_digits_value = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_ea_version_str = "1.04"; 

   h_adx_main = iADX(_Symbol, _Period, InpADX_Period);
   if(h_adx_main == INVALID_HANDLE)
     {
      Print("Error creating ADX indicator handle. Error code: ", GetLastError());
      return(INIT_FAILED);
     }
    
   g_min_bars_needed_for_ea = MathMax(InpPivotLookbackBars, InpADX_Period + InpDynamicADXMAPeriod + 5); 
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, InpHA_MAPeriod + InpHA_SignalMAPeriod + 10); 
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, 200); 
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, MathMax(InpSyn_M5_MACD_Slow, InpSyn_M5_EMA_Slow_Period) + 20); 
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, MathMax(InpSyn_M15_MACD_Slow, InpSyn_M15_EMA_Slow_Period) + 20); 
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, MathMax(InpSyn_H1_MACD_Slow, InpSyn_H1_EMA_Slow_Period) + 20); 


   if(InpPropStartBalanceOverride > 0.0) g_initial_challenge_balance_prop = InpPropStartBalanceOverride;
   else g_initial_challenge_balance_prop = AccountInfoDouble(ACCOUNT_BALANCE);
   
   g_prop_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE); 
   g_prop_highest_equity_peak = MathMax(AccountInfoDouble(ACCOUNT_EQUITY), g_initial_challenge_balance_prop); 
   g_prop_current_trading_days = 0;
   MqlDateTime temp_dt; TimeToStruct(TimeCurrent(),temp_dt); temp_dt.hour=0; temp_dt.min=0; temp_dt.sec=0;
   g_last_day_for_daily_reset = StructToTime(temp_dt); 
   ArrayFree(g_unique_trading_day_dates); 
   UpdateEAOpenPositionsState(); // Initial check of open positions

   string program_name_str = MQLInfoString(MQL_PROGRAM_NAME);
   Print(program_name_str + " (Master) Initialized. EA Version: " + g_ea_version_str + ", Build: " + IntegerToString(__MQL5BUILD__) + ". Initial Prop Balance for Dash: ", g_initial_challenge_balance_prop);
   
   prev_HA_Bias_Oscillator_Value = 0; 
   biasChangedToBullish_MQL = false;
   biasChangedToBearish_MQL = false;
   
   Dashboard_Init();

   double daily_dd_limit_pct = 0.0, max_acc_dd_pct = 0.0, stage_target_pct = 0.0;
   if (g_initial_challenge_balance_prop > 0) 
     {
      daily_dd_limit_pct = (InpDailyDDLimitDollars / g_initial_challenge_balance_prop) * 100.0;
      max_acc_dd_pct     = (InpMaxAccountDDLimitDollars / g_initial_challenge_balance_prop) * 100.0;
      stage_target_pct   = (InpStageTargetProfitDollars / g_initial_challenge_balance_prop) * 100.0;
     }

   Dashboard_UpdateStaticInfo(
      g_ea_version_str,              
      InpMagicNumber,                 
      g_initial_challenge_balance_prop, 
      daily_dd_limit_pct,             
      max_acc_dd_pct,                 
      stage_target_pct,               
      InpMinTradingDaysTotal_Prop,    
      _Symbol,                        
      EnumToString(_Period),          
      InpChallengeCost                
   );
   
   ChartVisuals_InitPivots(InpShowPivotVisuals, InpPivotUpColor, InpPivotDownColor);
   ChartVisuals_InitMarketBias(InpShowMarketBiasVisual, InpMarketBiasUpColor, InpMarketBiasDownColor);
   
   Comment("SynPropEA1 Initialized. Waiting for signals...");
   return(INIT_SUCCEEDED);
  }
   
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_adx_main != INVALID_HANDLE) IndicatorRelease(h_adx_main);
   Dashboard_Deinit();
   ChartVisuals_DeinitPivots(); 
   ChartVisuals_DeinitMarketBias();
   Print("SynPropEA1 (Master) Deinitialized. Reason: ", reason);
   Comment("SynPropEA1 Deinitialized.");
  }
   
//+------------------------------------------------------------------+
void OnTick()
  {
   bool isNewBar = false;
   if(iTime(_Symbol, _Period, 0) != PrevBarTime) 
     {
      PrevBarTime = iTime(_Symbol, _Period, 0);
      isNewBar = true;
     }

   UpdateEAOpenPositionsState(); // Update count and type of EA's open positions for this symbol

   MqlDateTime current_day_struct; TimeToStruct(TimeCurrent(), current_day_struct);
   current_day_struct.hour=0; current_day_struct.min=0; current_day_struct.sec=0;
   datetime current_day_start = StructToTime(current_day_struct);

   if(current_day_start > g_last_day_for_daily_reset)
     {
      g_prop_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE);
      g_last_day_for_daily_reset = current_day_start;
      Print("New day detected. Daily DD Balance Start updated to: ", g_prop_balance_at_day_start);
     }
   g_prop_highest_equity_peak = MathMax(g_prop_highest_equity_peak, AccountInfoDouble(ACCOUNT_EQUITY));
   
   string current_status_msg = "Monitoring..."; 
   int signal = 0; 
   is_session_active = IsInTradingSession(); 

   if(Bars(_Symbol, _Period) < g_min_bars_needed_for_ea && MQLInfoInteger(MQL_TESTER)==false) 
     {
      current_status_msg = StringFormat("Waiting for bars (%d/%d)", (int)Bars(_Symbol, _Period), g_min_bars_needed_for_ea);
     }
   else if(isNewBar) 
     {
      datetime currentCalcBarTime = iTime(_Symbol, _Period, 1); 
      double refPriceForPivots = iClose(_Symbol, _Period, 1); 
      PrintFormat("--- New Bar Calculation for Bar Closed at: %s ---", TimeToString(currentCalcBarTime, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
 
      if(!InpDisableHABias)
        {
         double current_HA_Bias_Oscillator = CalculateHeikinAshiBiasOscillator();
         bool prevBiasPositiveState = prev_HA_Bias_Oscillator_Value > InpHA_BiasThreshold;
         bool currentBiasPositiveState = current_HA_Bias_Oscillator > InpHA_BiasThreshold;
         biasChangedToBullish_MQL = !prevBiasPositiveState && currentBiasPositiveState;
         biasChangedToBearish_MQL = prevBiasPositiveState && !currentBiasPositiveState;
         val_HA_Bias_Oscillator = current_HA_Bias_Oscillator; 
         PrintFormat("HA Bias Osc (TF: %s, Value: %.5f). Prev Value: %.5f. ChangedToBull: %s, ChangedToBear: %s",
                     EnumToString(InpHA_Timeframe), val_HA_Bias_Oscillator, prev_HA_Bias_Oscillator_Value, 
                     biasChangedToBullish_MQL ? "Yes" : "No", biasChangedToBearish_MQL ? "Yes" : "No");
         prev_HA_Bias_Oscillator_Value = val_HA_Bias_Oscillator;
        }
      else 
        { val_HA_Bias_Oscillator = 0.0; biasChangedToBullish_MQL = false; biasChangedToBearish_MQL = false; }
 
      double adx_main_buf[1], adx_plus_buf[1], adx_minus_buf[1];
      if(Bars(_Symbol, _Period) > InpADX_Period + 1) 
        {
         val_ADX_Main = (CopyBuffer(h_adx_main, 0, 1, 1, adx_main_buf) > 0) ? adx_main_buf[0] : -1.0;
         val_ADX_Plus = (CopyBuffer(h_adx_main, 1, 1, 1, adx_plus_buf) > 0) ? adx_plus_buf[0] : -1.0;
         val_ADX_Minus = (CopyBuffer(h_adx_main, 2, 1, 1, adx_minus_buf) > 0) ? adx_minus_buf[0] : -1.0;
         PrintFormat("ADX (Main:%.2f, +DI:%.2f, -DI:%.2f) on bar close", val_ADX_Main, val_ADX_Plus, val_ADX_Minus);
         val_ADX_Threshold = CalculateADXThreshold();
         PrintFormat("ADX Threshold: %.2f", val_ADX_Threshold);
        }
      else
        { val_ADX_Main = -1.0; val_ADX_Plus = -1.0; val_ADX_Minus = -1.0; val_ADX_Threshold = InpStaticADXThreshold; }
 
      if(!InpDisableSynergyScore)
        {
         val_SynergyScore_M5 = CalculateSynergyScore(PERIOD_M5, InpSyn_M5_RSI_Period, InpSyn_M5_RSI_Weight, InpSyn_M5_EMA_Fast_Period, InpSyn_M5_EMA_Slow_Period, InpSyn_M5_Trend_Weight, InpSyn_M5_MACD_Fast, InpSyn_M5_MACD_Slow, InpSyn_M5_MACDV_Weight, 1);
         val_SynergyScore_M15 = CalculateSynergyScore(PERIOD_M15, InpSyn_M15_RSI_Period, InpSyn_M15_RSI_Weight, InpSyn_M15_EMA_Fast_Period, InpSyn_M15_EMA_Slow_Period, InpSyn_M15_Trend_Weight, InpSyn_M15_MACD_Fast, InpSyn_M15_MACD_Slow, InpSyn_M15_MACDV_Weight, 1);
         val_SynergyScore_H1 = CalculateSynergyScore(PERIOD_H1, InpSyn_H1_RSI_Period, InpSyn_H1_RSI_Weight, InpSyn_H1_EMA_Fast_Period, InpSyn_H1_EMA_Slow_Period, InpSyn_H1_Trend_Weight, InpSyn_H1_MACD_Fast, InpSyn_H1_MACD_Slow, InpSyn_H1_MACDV_Weight, 1);
         val_TotalSynergyScore = val_SynergyScore_M5 + val_SynergyScore_M15 + val_SynergyScore_H1;
         PrintFormat("Synergy (M5:%.2f, M15:%.2f, H1:%.2f, Total:%.2f) on bar close", val_SynergyScore_M5, val_SynergyScore_M15, val_SynergyScore_H1, val_TotalSynergyScore);
        }
      else { val_TotalSynergyScore = 0.0; }
 
      CalculatePivots(recent_pivot_high, recent_pivot_low, refPriceForPivots); 
      PrintFormat("Pivots (ref price %.5f for SL/TP): High: %s at %.5f, Low: %s at %.5f", refPriceForPivots, TimeToString(recent_pivot_high.time, TIME_MINUTES), recent_pivot_high.price, TimeToString(recent_pivot_low.time, TIME_MINUTES), recent_pivot_low.price);
      IdentifyPivotsForVisuals(); 
      Print("Is Trading Session Active: ", is_session_active ? "Yes" : "No");
      PrintFormat("EA Positions: Count=%d, Type=%s", g_ea_open_positions_count, EnumToString(g_ea_open_positions_type));
      
      // --- Trade Decision Logic ---
      bool allow_new_trade = false;
      signal = GetTradingSignal(); // Get the potential signal first

      if(g_ea_open_positions_count == 0) {
          allow_new_trade = true; // No open trades, can open new one if signal exists
      } else { // Existing EA trade(s) open
          if (g_ea_open_positions_count < InpPyramidingMaxOrders) {
              // Check if new signal is in the same direction as existing trades
              if (signal == 1 && g_ea_open_positions_type == ORDER_TYPE_BUY) {
                  allow_new_trade = true;
                  Print("Pyramiding Check: Existing LONG, new LONG signal. Pyramiding allowed.");
              } else if (signal == -1 && g_ea_open_positions_type == ORDER_TYPE_SELL) {
                  allow_new_trade = true;
                  Print("Pyramiding Check: Existing SHORT, new SHORT signal. Pyramiding allowed.");
              } else if (signal != 0) { // New signal exists but is opposite or type mismatch
                  PrintFormat("Pyramiding Check: Existing %s, new %s signal. Opposite trade NOT allowed.", EnumToString(g_ea_open_positions_type), (signal==1?"LONG":"SHORT"));
              }
          } else {
              PrintFormat("Pyramiding Check: Max orders (%d) already open. No further pyramiding.", InpPyramidingMaxOrders);
          }
      }
      
      if(is_session_active && InpAllowTrades && allow_new_trade && signal != 0)
        {
         if(signal == 1) { current_status_msg = "Signal: LONG"; }
         else if(signal == -1) { current_status_msg = "Signal: SHORT"; }
         
         Print("Trade Attempt Conditions Met: Signal=", (signal == 1 ? "LONG" : "SHORT"));
         double entry_price_for_calc; 
         if(signal == 1) entry_price_for_calc = SymbolInfoDouble(_Symbol, SYMBOL_ASK); 
         else entry_price_for_calc = SymbolInfoDouble(_Symbol, SYMBOL_BID);            

         double sl_price = CalculateStopLoss(signal, entry_price_for_calc);
         PrintFormat("Trade Logic: EntryForCalc=%.5f, Calculated SL=%.5f", entry_price_for_calc, sl_price);
            
         if(sl_price != 0.0) 
           {
            double tp_price = CalculateTakeProfit(signal, entry_price_for_calc, sl_price);
            PrintFormat("Trade Logic: Calculated TP=%.5f", tp_price);
               
            if(tp_price != 0.0) 
              {
               double sl_distance_points_for_lot = MathAbs(entry_price_for_calc - sl_price) / g_point_value;
               if(g_point_value > 0 && sl_distance_points_for_lot > g_point_value) 
                 {
                  double trade_lot_size = CalculateLotSize(sl_distance_points_for_lot);
                  PrintFormat("Trade Logic: SL Dist Points = %.1f, Lot = %.2f", sl_distance_points_for_lot, trade_lot_size);

                  if(trade_lot_size >= SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
                    {
                     string trade_comment = StringFormat("SynPropEA v%s %s %s #%d SL@%.*f TP@%.*f",
                                                         g_ea_version_str,
                                                         (signal==1?"Buy":"Sell"), _Symbol, 
                                                         g_ea_open_positions_count + 1, // Pyramiding order number
                                                         g_digits_value, sl_price, g_digits_value, tp_price);
                     OpenTrade(signal, trade_lot_size, sl_price, tp_price, trade_comment);
                    }
                  else 
                    { Print("Trade Logic: Calculated lot size is too small. No trade."); }
                 } 
               else 
                 { PrintFormat("Trade Logic: Cannot calculate Lot Size, SL distance (%.1f points) is too small or g_point_value invalid.", sl_distance_points_for_lot); }
              }
            else
              { Print("Trade Logic: TP calculation returned 0.0. No trade."); }
           }
         else
           { Print("Trade Logic: SL calculation returned 0.0. No trade."); }
        }
       else // Conditions for new trade not met
        {
          if (!is_session_active) { current_status_msg = "Session Inactive"; }
          else if (!InpAllowTrades) { current_status_msg = "Trading Disabled"; }
          else if (signal == 0 && g_ea_open_positions_count == 0) { current_status_msg = "In Session - No Signal"; }
          else if (g_ea_open_positions_count >= InpPyramidingMaxOrders) { current_status_msg = "Max Orders Open"; }
          else if (g_ea_open_positions_count > 0) { current_status_msg = StringFormat("Position Open (%s)", EnumToString(g_ea_open_positions_type));}
          else { current_status_msg = "No Trade Condition"; } // Generic if other conditions fail
          if (signal !=0 ) Print("Trade conditions not fully met (AllowTrades, Session, Pyramiding rules). No new trade initiated.");
        }
        
      ChartVisuals_UpdatePivots(g_identified_pivots_high, g_identified_pivots_low, InpShowPivotVisuals, InpPivotUpColor, InpPivotDownColor); 
      ChartVisuals_UpdateMarketBias(val_HA_Bias_Oscillator, InpShowMarketBiasVisual); 
      // Update dashboard status based on whether we are actively looking for a trade signal
      bool can_look_for_trade = is_session_active && InpAllowTrades && 
                                (g_ea_open_positions_count < InpPyramidingMaxOrders || 
                                (g_ea_open_positions_count > 0 && signal !=0 && 
                                 ((signal == 1 && g_ea_open_positions_type == ORDER_TYPE_BUY) || (signal == -1 && g_ea_open_positions_type == ORDER_TYPE_SELL))
                                ));
      Dashboard_UpdateStatus(current_status_msg, (signal != 0 && can_look_for_trade) ); 
      Dashboard_UpdateSlaveStatus("N/A", 0.0, 0.0, 0.0, false); 
     } 
    else if (Bars(_Symbol, _Period) >= g_min_bars_needed_for_ea && !isNewBar) 
     {
        // Update status message on non-new-bar ticks
        if (!is_session_active) { current_status_msg = "Session Inactive"; }
        else if (!InpAllowTrades) { current_status_msg = "Trading Disabled"; }
        else if (g_ea_open_positions_count >= InpPyramidingMaxOrders) { current_status_msg = "Max Orders Open"; }
        else if (g_ea_open_positions_count > 0) { current_status_msg = StringFormat("Position Open (%s)", EnumToString(g_ea_open_positions_type));}
        else { current_status_msg = "Monitoring...";  }
        Dashboard_UpdateStatus(current_status_msg, false); // Not actively signaling on non-new-bar
     }

   Dashboard_UpdateDynamicInfo(
      AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoDouble(ACCOUNT_EQUITY),
      g_prop_balance_at_day_start, g_prop_highest_equity_peak, g_prop_current_trading_days,    
      g_ea_open_positions_count, 
      0, 0, 
      is_session_active 
   );

   string comment_str;
   if(Bars(_Symbol, _Period) >= g_min_bars_needed_for_ea)
     {
      comment_str = StringFormat("SynTotal: %.1f | HA Bias: %.2f | ADX: %.1f | Sess: %s | Trades: %d (%s)",
                                 val_TotalSynergyScore, val_HA_Bias_Oscillator, val_ADX_Main,
                                 is_session_active ? "Active" : "Inactive", 
                                 g_ea_open_positions_count,
                                 (g_ea_open_positions_type == WRONG_VALUE ? "None" : EnumToString(g_ea_open_positions_type))
                                 );
     }
   else
     {
      comment_str = StringFormat("Waiting for bars (%d/%d)...", (int)Bars(_Symbol, _Period), g_min_bars_needed_for_ea);
     }
   Comment(comment_str);
  }

//+------------------------------------------------------------------+
// Definitions for CalculateSMAOnArray, CalculateHeikinAshiBiasOscillator, 
// CalculateADXThreshold, CalculateSynergyScore, CalculatePivots, GetTradingSignal
// (These should be present from your existing complete EA file)
//+------------------------------------------------------------------+
bool CalculateSMAOnArray(const double &source_array[], int source_total, int period, double &result_array[])
  {
   if(period <= 0 || source_total < period)
     {
      PrintFormat("CalculateSMAOnArray: Invalid parameters. Period: %d, Source Total: %d. Cannot calculate SMA.", period, source_total);
      return false;
     }
   int result_size = source_total - period + 1;
   if(ArrayResize(result_array, result_size) < 0)
     {
      Print("CalculateSMAOnArray: Failed to resize result array.");
      return false;
     }
   for(int i = 0; i < result_size; i++) 
     {
      double sum = 0;
      for(int j = 0; j < period; j++) 
        {
         sum += source_array[i + j];
        }
      result_array[i] = sum / period;
     }
   return true;
  }

//+------------------------------------------------------------------+
double CalculateHeikinAshiBiasOscillator() 
  {
   ENUM_TIMEFRAMES ha_tf = InpHA_Timeframe;
   int ma_period = InpHA_MAPeriod;
   int signal_period = InpHA_SignalMAPeriod;

   int ha_values_needed_for_mas = ma_period + signal_period -1; 
    if(ha_values_needed_for_mas <=0) ha_values_needed_for_mas=1; 

   int bars_to_calculate_ha = ha_values_needed_for_mas + 5; 

   if(Bars(_Symbol, ha_tf) < bars_to_calculate_ha)
     {
      PrintFormat("CalculateHeikinAshiBiasOscillator: Not enough bars on %s (%d) to calculate. Need %d.",
                  EnumToString(ha_tf), (int)Bars(_Symbol, ha_tf), bars_to_calculate_ha);
      return 0.0;
     }

   double ha_open_series[], ha_close_series[];
   if(ArrayResize(ha_open_series, bars_to_calculate_ha) < 0 || ArrayResize(ha_close_series, bars_to_calculate_ha) < 0)
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to resize HA series arrays.");
      return 0.0;
     }
   ArraySetAsSeries(ha_open_series, true); 
   ArraySetAsSeries(ha_close_series, true);                            

   for(int i = bars_to_calculate_ha - 1; i >= 0; i--) 
     {
      double O = iOpen(_Symbol, ha_tf, i);
      double H = iHigh(_Symbol, ha_tf, i);
      double L = iLow(_Symbol, ha_tf, i);
      double C = iClose(_Symbol, ha_tf, i);

      if(O == 0 && C == 0 && H == 0 && L == 0) 
        {
         if(i < bars_to_calculate_ha - 1) 
           {
            ha_close_series[i] = ha_close_series[i + 1]; 
            ha_open_series[i] = ha_open_series[i + 1];
           }
         else 
           {
            PrintFormat("CalculateHeikinAshiBiasOscillator: Oldest bar (shift %d) for HA calculation on %s is empty. Cannot proceed.", i, EnumToString(ha_tf));
            return 0.0; 
           }
         continue;
        }
      ha_close_series[i] = (O + H + L + C) / 4.0;
      if(i == bars_to_calculate_ha - 1) 
        {
         ha_open_series[i] = (O + C) / 2.0;
        }
      else 
        {
         ha_open_series[i] = (ha_open_series[i + 1] + ha_close_series[i + 1]) / 2.0; 
        }
     }

   double ha_open_for_ma[], ha_close_for_ma[];
   if(ArrayResize(ha_open_for_ma, ha_values_needed_for_mas) < 0 || ArrayResize(ha_close_for_ma, ha_values_needed_for_mas) < 0)
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to resize HA _for_ma arrays.");
      return 0.0;
     }
   for(int k = 0; k < ha_values_needed_for_mas; k++)
     {
      ha_open_for_ma[k] = ha_open_series[k+1]; 
      ha_close_for_ma[k] = ha_close_series[k+1];
     }
    ArraySetAsSeries(ha_open_for_ma, false); 
    ArraySetAsSeries(ha_close_for_ma, false);

   double ha_close_smooth[], ha_open_smooth[];
   if(!CalculateSMAOnArray(ha_close_for_ma, ha_values_needed_for_mas, ma_period, ha_close_smooth))
     {
      PrintFormat("CalculateHeikinAshiBiasOscillator: Error calculating SMA for HA_Close_Smooth.");
      return 0.0;
     }
   if(!CalculateSMAOnArray(ha_open_for_ma, ha_values_needed_for_mas, ma_period, ha_open_smooth))
     {
      PrintFormat("CalculateHeikinAshiBiasOscillator: Error calculating SMA for HA_Open_Smooth.");
      return 0.0;
     }

   int smoothed_array_size = ArraySize(ha_close_smooth); 
   if(smoothed_array_size < signal_period) 
     {
      PrintFormat("CalculateHeikinAshiBiasOscillator: Smoothed HA array size %d is less than signal_period %d.", smoothed_array_size, signal_period);
      return 0.0;
     }
   double raw_bias_osc[];
   if(ArrayResize(raw_bias_osc, smoothed_array_size) < 0)
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to resize raw_bias_osc array.");
      return 0.0;
     }
   for(int k = 0; k < smoothed_array_size; k++)
     {
      raw_bias_osc[k] = ha_close_smooth[k] - ha_open_smooth[k]; 
     }

   double final_ha_osc_values[];
   if(!CalculateSMAOnArray(raw_bias_osc, smoothed_array_size, signal_period, final_ha_osc_values))
     {
      PrintFormat("CalculateHeikinAshiBiasOscillator: Error calculating SMA for Final_HA_Osc.");
      return 0.0;
     }

   int final_osc_array_size = ArraySize(final_ha_osc_values);
   if(final_osc_array_size > 0)
     {
      return final_ha_osc_values[0]; 
     }
   else
     {
      Print("CalculateHeikinAshiBiasOscillator: Final HA oscillator array is empty after MA calculations.");
      return 0.0;
     }
  }

//+------------------------------------------------------------------+
double CalculateADXThreshold()
  {
   if(!InpUseDynamicADX)
     {
      return InpStaticADXThreshold;
     }
   if(Bars(_Symbol, _Period) < InpADX_Period + InpDynamicADXMAPeriod + 2) 
     {
      PrintFormat("CalculateADXThreshold: Not enough bars (%d) on %s for dynamic ADX threshold. Need %d. Using static.",
                  (int)Bars(_Symbol, _Period), EnumToString(_Period), InpADX_Period + InpDynamicADXMAPeriod + 2);
      return InpStaticADXThreshold;
     }
     
   int adx_ma_period = InpDynamicADXMAPeriod;
   double adx_history[];
   if(ArrayResize(adx_history, adx_ma_period) < 0) 
     {
      Print("CalculateADXThreshold: Error resizing adx_history array");
      return InpStaticADXThreshold;
     }

   int copied = CopyBuffer(h_adx_main, 0, 1, adx_ma_period, adx_history); 
   if(copied < adx_ma_period)
     {
      PrintFormat("CalculateADXThreshold: Not enough ADX history copied for dynamic threshold MA. Requested %d, Copied %d. Using static.",
                  adx_ma_period, copied);
      return InpStaticADXThreshold;
     }
     
   double adx_sum = 0;
   int count = 0;
   for(int i = 0; i < adx_ma_period; i++)
     {
      if(adx_history[i] > 0) 
        {
         adx_sum += adx_history[i];
         count++;
        }
     }
     
   if(count == 0)          
     {
      Print("CalculateADXThreshold: No valid ADX values found for SMA. Using static.");
      return InpStaticADXThreshold; 
     }
     
   double adx_sma = adx_sum / count;
   double dynamic_threshold = adx_sma * InpDynamicADXMultiplier;
   
   return MathMax(dynamic_threshold, InpADXMinThreshold); 
  }

//+------------------------------------------------------------------+
double CalculateSynergyScore(ENUM_TIMEFRAMES tf, 
                             int rsi_period, double rsi_w,
                             int ema_fast_period, int ema_slow_period, double trend_w,
                             int macd_fast_period, int macd_slow_period, double macdv_w,
                             int bar_idx = 1) 
  {
   int min_bars_tf = MathMax(rsi_period, MathMax(ema_slow_period, macd_slow_period)) + bar_idx + 20; 
   if(Bars(_Symbol, tf) < min_bars_tf)
     {
      PrintFormat("CalculateSynergyScore: Not enough bars on %s (%d) to calculate. Need ~%d.",
                  EnumToString(tf), (int)Bars(_Symbol, tf), min_bars_tf);
      return 0.0;
     }

   double score = 0;

   double rsi_val_arr[1];
   int rsi_handle = iRSI(_Symbol, tf, rsi_period, PRICE_CLOSE);
   if(rsi_handle != INVALID_HANDLE)
     {
      if(CopyBuffer(rsi_handle, 0, bar_idx, 1, rsi_val_arr) > 0)
        {
         if(rsi_val_arr[0] > 55) score += 1.0 * rsi_w;
         else if(rsi_val_arr[0] < 45) score -= 1.0 * rsi_w;
        }
      else PrintFormat("CSynS %s: Failed to copy RSI buffer, shift %d. Err: %d", EnumToString(tf), bar_idx, GetLastError());
      IndicatorRelease(rsi_handle);
     }
   else PrintFormat("CSynS %s: Failed to create iRSI handle. Err: %d", EnumToString(tf), GetLastError());

   double ema_fast_arr[1], ema_slow_arr[1];
   int ema_fast_handle = iMA(_Symbol, tf, ema_fast_period, 0, MODE_EMA, PRICE_CLOSE);
   int ema_slow_handle = iMA(_Symbol, tf, ema_slow_period, 0, MODE_EMA, PRICE_CLOSE);

   if(ema_fast_handle != INVALID_HANDLE && ema_slow_handle != INVALID_HANDLE)
     {
      bool fast_ok = CopyBuffer(ema_fast_handle, 0, bar_idx, 1, ema_fast_arr) > 0;
      bool slow_ok = CopyBuffer(ema_slow_handle, 0, bar_idx, 1, ema_slow_arr) > 0;
      if(fast_ok && slow_ok)
        {
         if(ema_fast_arr[0] > ema_slow_arr[0]) score += 1.0 * trend_w;
         else if(ema_fast_arr[0] < ema_slow_arr[0]) score -= 1.0 * trend_w;
        }
      else PrintFormat("CSynS %s: Failed to copy EMA buffers. FastOK:%s, SlowOK:%s", EnumToString(tf), fast_ok?"T":"F", slow_ok?"T":"F");
     }
   else PrintFormat("CSynS %s: Failed to create EMA handles. FastH:%d, SlowH:%d", EnumToString(tf), ema_fast_handle, ema_slow_handle);
   
   if(ema_fast_handle != INVALID_HANDLE) IndicatorRelease(ema_fast_handle);
   if(ema_slow_handle != INVALID_HANDLE) IndicatorRelease(ema_slow_handle);
   
   double macd_val_curr_arr[1], macd_val_prev_arr[1]; 
   int macd_handle = iMACD(_Symbol, tf, macd_fast_period, macd_slow_period, 9, PRICE_CLOSE); 
   if(macd_handle != INVALID_HANDLE)
     {
      bool curr_ok = CopyBuffer(macd_handle, MAIN_LINE, bar_idx, 1, macd_val_curr_arr) > 0;
      bool prev_ok = CopyBuffer(macd_handle, MAIN_LINE, bar_idx + 1, 1, macd_val_prev_arr) > 0; 

      if(curr_ok && prev_ok)
        {
         if(macd_val_curr_arr[0] > macd_val_prev_arr[0]) score += 1.0 * macdv_w;
         else if(macd_val_curr_arr[0] < macd_val_prev_arr[0]) score -= 1.0 * macdv_w;
        }
      else PrintFormat("CSynS %s: Failed to copy MACD buffers. CurrOK:%s, PrevOK:%s", EnumToString(tf), curr_ok?"T":"F", prev_ok?"T":"F");
      IndicatorRelease(macd_handle);
     }
   else PrintFormat("CSynS %s: Failed to create iMACD handle. Err: %d", EnumToString(tf), GetLastError());
   
   return score;
  }

//+------------------------------------------------------------------+
void CalculatePivots(PivotPoint &overall_highest_pivot_h, PivotPoint &overall_lowest_pivot_l, double ref_price)
  {
   overall_highest_pivot_h.time = 0;
   overall_highest_pivot_h.price = 0.0; 
   overall_lowest_pivot_l.time = 0;
   overall_lowest_pivot_l.price = DBL_MAX; 

   int bars_available = (int)Bars(_Symbol, _Period); 
   if(bars_available <= InpPivotLeftBars + InpPivotRightBars + 1) return;
   
   int local_lookback = MathMin(InpPivotLookbackBars, bars_available - (InpPivotLeftBars + InpPivotRightBars +1));
   local_lookback = MathMax(local_lookback, InpPivotLeftBars + InpPivotRightBars + 1);


   int max_scan_shift = MathMin(local_lookback - 1, bars_available - 1 - InpPivotLeftBars);
   max_scan_shift = MathMax(InpPivotRightBars, max_scan_shift);

   for(int i = InpPivotRightBars; i <= max_scan_shift; i++) 
     {
      if(i + InpPivotLeftBars >= bars_available || i - InpPivotRightBars < 0) continue;
      bool is_high = true;
      double candidate_price = iHigh(_Symbol, _Period, i);
      for(int L = 1; L <= InpPivotLeftBars; L++) if(candidate_price <= iHigh(_Symbol, _Period, i + L)) {is_high=false; break;}
      if(!is_high) continue;
      for(int R = 1; R <= InpPivotRightBars; R++) if(candidate_price < iHigh(_Symbol, _Period, i - R)) {is_high=false; break;} 
      
      if(is_high && candidate_price > ref_price) 
        {
         if(overall_highest_pivot_h.time == 0 || candidate_price > overall_highest_pivot_h.price)
           {
            overall_highest_pivot_h.price = candidate_price;
            overall_highest_pivot_h.time = iTime(_Symbol, _Period, i);
           }
        }
     }

   for(int i = InpPivotRightBars; i <= max_scan_shift; i++) 
     {
      if(i + InpPivotLeftBars >= bars_available || i - InpPivotRightBars < 0) continue;
      bool is_low = true;
      double candidate_price = iLow(_Symbol, _Period, i);
      for(int L = 1; L <= InpPivotLeftBars; L++) if(candidate_price >= iLow(_Symbol, _Period, i + L)) {is_low=false; break;}
      if(!is_low) continue;
      for(int R = 1; R <= InpPivotRightBars; R++) if(candidate_price > iLow(_Symbol, _Period, i - R)) {is_low=false; break;} 

      if(is_low && candidate_price < ref_price) 
        {
         if(overall_lowest_pivot_l.time == 0 || candidate_price < overall_lowest_pivot_l.price)
           {
            overall_lowest_pivot_l.price = candidate_price;
            overall_lowest_pivot_l.time = iTime(_Symbol, _Period, i);
           }
        }
     }
     if(overall_lowest_pivot_l.price == DBL_MAX) overall_lowest_pivot_l.price = 0.0; 
  }

//+------------------------------------------------------------------+
int GetTradingSignal() 
  {
   bool adx_ok = (val_ADX_Main > val_ADX_Threshold && val_ADX_Main > 0 && val_ADX_Main != -1.0);
   
   bool ha_bias_long_ok = InpDisableHABias ? true : biasChangedToBullish_MQL;
   bool ha_bias_short_ok = InpDisableHABias ? true : biasChangedToBearish_MQL;
 
   bool synergy_long_ok = InpDisableSynergyScore ? true : (val_TotalSynergyScore > 0); 
   bool synergy_short_ok = InpDisableSynergyScore ? true : (val_TotalSynergyScore < 0); 

   if(synergy_long_ok && ha_bias_long_ok && adx_ok)
     {
      return 1; // LONG
     }
   if(synergy_short_ok && ha_bias_short_ok && adx_ok)
     {
      return -1; // SHORT
     }
   return 0; // NO SIGNAL
  }
//+------------------------------------------------------------------+
