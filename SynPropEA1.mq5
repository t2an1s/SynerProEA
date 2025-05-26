

   // SynPropEA1.mq5// SynPropEA1.mq5
   #property copyright "t2an1s"
   #property link      "https://github.com/t2an1s/SynerProEA"
   #property version   "1.01" 
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
   
   // Challenge Parameters (Static Limits for Prop Account)
   input double InpChallengeCost     = 700.0; // For info, not directly used in DD/Target calcs on dash
   input int    InpChallengeStages   = 1;     // For info
   input double InpStageTargetProfitDollars = 1000.0; // Renamed for clarity: this is the PROFIT TARGET in dollars
   input double InpMaxAccountDDLimitDollars = 4000.0; // Renamed for clarity: this is the MAX DD LIMIT in dollars
   input double InpDailyDDLimitDollars    = 2000.0; // Renamed for clarity: this is the DAILY DD LIMIT in dollars
   input double InpPropStartBalanceOverride = 0.0;  // If > 0, overrides account balance at init for calcs
   input int    InpMinTradingDaysTotal_Prop = 5;    // NEW: Total minimum trading days required for prop
   
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
   
   long   broker_time_gmt_offset_seconds;
   bool   is_session_active;
   datetime PrevBarTime; 
   string g_ea_version_str = "1.01"; // For dashboard
   
   // --- NEW Global Variables for Dashboard Data Tracking (Prop Account) ---
   double   g_initial_challenge_balance_prop; // The defined starting balance for DD/Target calculations
   double   g_prop_balance_at_day_start;
   double   g_prop_highest_equity_peak;
   int      g_prop_current_trading_days;
   datetime g_last_day_for_daily_reset; // To track day changes for daily DD reset
   datetime g_unique_trading_day_dates[]; // Array to store unique dates of trading activity
   
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
   // Helper to add unique trading day
   void AddUniqueTradingDay(datetime trade_event_time)
     {
      MqlDateTime dt_struct;
      TimeToStruct(trade_event_time, dt_struct);
      datetime date_only = StructToTime(dt_struct); // Normalizes to 00:00:00 of that day
   
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
   //+------------------------------------------------------------------+
int OnInit()
  {
   PrevBarTime = 0; 
   CalculateGMTOffset();

   h_adx_main = iADX(_Symbol, _Period, InpADX_Period);
   if(h_adx_main == INVALID_HANDLE)
     {
      Print("Error creating ADX indicator handle. Error code: ", GetLastError());
      return(INIT_FAILED);
     }

   // --- Initialize Dashboard Tracking Variables ---
   if(InpPropStartBalanceOverride > 0.0)
     {
      g_initial_challenge_balance_prop = InpPropStartBalanceOverride;
     }
   else
     {
      g_initial_challenge_balance_prop = AccountInfoDouble(ACCOUNT_BALANCE); // Use current balance if no override
     }
   g_prop_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE); 
   g_prop_highest_equity_peak = MathMax(AccountInfoDouble(ACCOUNT_EQUITY), g_initial_challenge_balance_prop); 
   g_prop_current_trading_days = 0;
   g_last_day_for_daily_reset = TimeCurrent(); 
   ArrayFree(g_unique_trading_day_dates); 

   string program_name_str = MQLInfoString(MQL_PROGRAM_NAME);
   Print(program_name_str + " (Master) Initialized. EA Version: " + g_ea_version_str + ", Build: " + IntegerToString(__MQL5BUILD__) + ". Initial Prop Balance for Dash: ", g_initial_challenge_balance_prop);
   
   prev_HA_Bias_Oscillator_Value = 0; 
   biasChangedToBullish_MQL = false;
   biasChangedToBearish_MQL = false;

   // --- BEGIN DASHBOARD CALLS ---
   
   Dashboard_Init();

   // Calculate percentages from dollar amounts for the dashboard
   double daily_dd_limit_pct = 0.0;
   double max_acc_dd_pct = 0.0;
   double stage_target_pct = 0.0;

   if (g_initial_challenge_balance_prop > 0) // Avoid division by zero
     {
      daily_dd_limit_pct = (InpDailyDDLimitDollars / g_initial_challenge_balance_prop) * 100.0;
      max_acc_dd_pct     = (InpMaxAccountDDLimitDollars / g_initial_challenge_balance_prop) * 100.0;
      stage_target_pct   = (InpStageTargetProfitDollars / g_initial_challenge_balance_prop) * 100.0;
     }

   Dashboard_UpdateStaticInfo(
      g_ea_version_str,               // Use your existing global for EA version string
      InpMagicNumber,                 // Use your existing global input
      g_initial_challenge_balance_prop, // Use the initialized global variable
      daily_dd_limit_pct,             // Calculated percentage
      max_acc_dd_pct,                 // Calculated percentage
      stage_target_pct,               // Calculated percentage
      InpMinTradingDaysTotal_Prop,    // Use your existing global input
      _Symbol,                        
      EnumToString(_Period),          
      InpChallengeCost                // Use your existing global input
   );

   // --- END DASHBOARD CALLS ---
   
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
   
      int min_bars_needed = MathMax(InpPivotLookbackBars, InpADX_Period + InpDynamicADXMAPeriod + 5); 
      min_bars_needed = MathMax(min_bars_needed, InpHA_MAPeriod + InpHA_SignalMAPeriod + 10); 
      min_bars_needed = MathMax(min_bars_needed, 200); 
      min_bars_needed = MathMax(min_bars_needed, MathMax(InpSyn_M5_MACD_Slow, InpSyn_M5_EMA_Slow_Period) + 20); 
      min_bars_needed = MathMax(min_bars_needed, MathMax(InpSyn_M15_MACD_Slow, InpSyn_M15_EMA_Slow_Period) + 20); 
      min_bars_needed = MathMax(min_bars_needed, MathMax(InpSyn_H1_MACD_Slow, InpSyn_H1_EMA_Slow_Period) + 20); 
   
   
      if(Bars(_Symbol, _Period) < min_bars_needed)
        {
         Comment(StringFormat("Not enough bars on current chart (%s) for calculations. Have %d, Need ~%d.",
                   EnumToString(_Period), (int)Bars(_Symbol, _Period), min_bars_needed));
         return;
        }
   
      if(isNewBar)
        {
         datetime currentCalcBarTime = iTime(_Symbol, _Period, 1); 
         double refPriceForPivots = iClose(_Symbol, _Period, 1); 
   
         PrintFormat("--- New Bar Calculation for Bar Closed at: %s ---", TimeToString(currentCalcBarTime, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
         // Comment updated below to include dashboard status
   
         if(!InpDisableHABias)
           {
            double current_HA_Bias_Oscillator = CalculateHeikinAshiBiasOscillator();
            
            bool prevBiasPositiveState = prev_HA_Bias_Oscillator_Value > InpHA_BiasThreshold;
            bool currentBiasPositiveState = current_HA_Bias_Oscillator > InpHA_BiasThreshold;
   
            biasChangedToBullish_MQL = !prevBiasPositiveState && currentBiasPositiveState;
            biasChangedToBearish_MQL = prevBiasPositiveState && !currentBiasPositiveState;
            
            val_HA_Bias_Oscillator = current_HA_Bias_Oscillator; 
            prev_HA_Bias_Oscillator_Value = val_HA_Bias_Oscillator; 
   
            PrintFormat("HA Bias Osc (TF: %s, Value: %.5f). Prev Value: %.5f. ChangedToBull: %s, ChangedToBear: %s",
                        EnumToString(InpHA_Timeframe),
                        val_HA_Bias_Oscillator,
                        prev_HA_Bias_Oscillator_Value, 
                        biasChangedToBullish_MQL ? "Yes" : "No",
                        biasChangedToBearish_MQL ? "Yes" : "No");
           }
         else 
           { 
            val_HA_Bias_Oscillator = 0.0; 
            biasChangedToBullish_MQL = false;
            biasChangedToBearish_MQL = false;
           }
   
   
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
           {
            Print("Not enough bars for ADX calculation on current chart timeframe.");
            val_ADX_Main = -1.0; val_ADX_Plus = -1.0; val_ADX_Minus = -1.0; val_ADX_Threshold = InpStaticADXThreshold;
           }
   
         if(!InpDisableSynergyScore)
           {
            val_SynergyScore_M5 = CalculateSynergyScore(PERIOD_M5, 
                                                        InpSyn_M5_RSI_Period, InpSyn_M5_RSI_Weight,
                                                        InpSyn_M5_EMA_Fast_Period, InpSyn_M5_EMA_Slow_Period, InpSyn_M5_Trend_Weight,
                                                        InpSyn_M5_MACD_Fast, InpSyn_M5_MACD_Slow, InpSyn_M5_MACDV_Weight, 1);
            val_SynergyScore_M15 = CalculateSynergyScore(PERIOD_M15,
                                                         InpSyn_M15_RSI_Period, InpSyn_M15_RSI_Weight,
                                                         InpSyn_M15_EMA_Fast_Period, InpSyn_M15_EMA_Slow_Period, InpSyn_M15_Trend_Weight,
                                                         InpSyn_M15_MACD_Fast, InpSyn_M15_MACD_Slow, InpSyn_M15_MACDV_Weight, 1);
            val_SynergyScore_H1 = CalculateSynergyScore(PERIOD_H1,
                                                        InpSyn_H1_RSI_Period, InpSyn_H1_RSI_Weight,
                                                        InpSyn_H1_EMA_Fast_Period, InpSyn_H1_EMA_Slow_Period, InpSyn_H1_Trend_Weight,
                                                        InpSyn_H1_MACD_Fast, InpSyn_H1_MACD_Slow, InpSyn_H1_MACDV_Weight, 1);
            val_TotalSynergyScore = val_SynergyScore_M5 + val_SynergyScore_M15 + val_SynergyScore_H1;
            PrintFormat("Synergy (M5:%.2f, M15:%.2f, H1:%.2f, Total:%.2f) on bar close", val_SynergyScore_M5, val_SynergyScore_M15, val_SynergyScore_H1, val_TotalSynergyScore);
           }
         else { val_TotalSynergyScore = 0.0; }
   
         CalculatePivots(recent_pivot_high, recent_pivot_low, refPriceForPivots);
         PrintFormat("Pivots (ref price %.5f): High: %s at %.5f, Low: %s at %.5f",
                     refPriceForPivots,
                     TimeToString(recent_pivot_high.time, TIME_MINUTES), recent_pivot_high.price,
                     TimeToString(recent_pivot_low.time, TIME_MINUTES), recent_pivot_low.price);
   
         is_session_active = IsInTradingSession();
         Print("Is Trading Session Active: ", is_session_active ? "Yes" : "No");
         
         string current_status_msg = "Monitoring...";
         if(is_session_active)
           {
            int signal = GetTradingSignal();
            if(signal == 1) { current_status_msg = "Signal: LONG"; }
            else if(signal == -1) { current_status_msg = "Signal: SHORT"; }
            else { current_status_msg = "In Session - No Signal"; }
            
            if(signal != 0) Print("Trading Signal on Bar Close: ", (signal == 1 ? "LONG" : "SHORT"));
            else Print("No Trading Signal on Bar Close.");
           }
          else { current_status_msg = "Session Inactive"; }
   
         // --- DASHBOARD CALLS (NEW BAR) ---
         ChartVisuals_UpdatePivots(recent_pivot_high, recent_pivot_low, InpShowPivotVisuals);
         ChartVisuals_UpdateMarketBias(val_HA_Bias_Oscillator, InpShowMarketBiasVisual); // Assuming this takes the raw oscillator value
         Dashboard_UpdateStatus(current_status_msg, (is_session_active && GetTradingSignal() !=0)); // Pass if signal is active
         Dashboard_UpdateSlaveStatus("N/A", 0.0, 0.0, 0.0, false); // Placeholder slave data
         // --- END DASHBOARD CALLS ---
        }
   
      // Simplified Comment for chart, main info will be on dashboard
      string comment_str = StringFormat("SynTotal: %.1f | HA Bias: %.2f | ADX: %.1f | Sess: %s",
                                        val_TotalSynergyScore,
                                        val_HA_Bias_Oscillator,
                                        val_ADX_Main,
                                        is_session_active ? "Active" : "Inactive");
      Comment(comment_str);
     }

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

   int ha_values_needed_for_mas = ma_period + signal_period - 1;
   if(ha_values_needed_for_mas <= 0)
     {
      PrintFormat("CalculateHeikinAshiBiasOscillator: Invalid MA periods (ma_period=%d, signal_period=%d)", ma_period, signal_period);
      return 0.0;
     }
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
      int series_idx = (ha_values_needed_for_mas - 1) - k;
      ha_open_for_ma[k] = ha_open_series[series_idx];
      ha_close_for_ma[k] = ha_close_series[series_idx];
     }

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
      return final_ha_osc_values[final_osc_array_size - 1];
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
   int adx_ma_period = MathMin(InpDynamicADXMAPeriod, (int)Bars(_Symbol, _Period) - InpADX_Period - 2); 
   adx_ma_period = MathMax(1, adx_ma_period); 
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
   
   int max_scan_shift = MathMin(InpPivotLookbackBars - 1, bars_available - 1 - InpPivotLeftBars);
   max_scan_shift = MathMax(InpPivotRightBars, max_scan_shift);

   for(int i = InpPivotRightBars; i <= max_scan_shift; i++) 
     {
      if(i + InpPivotLeftBars >= bars_available || i - InpPivotRightBars < 0) continue;
      bool is_high = true;
      double candidate_price = iHigh(_Symbol, _Period, i);
      for(int L = 1; L <= InpPivotLeftBars; L++) if(candidate_price <= iHigh(_Symbol, _Period, i + L)) {is_high=false; break;}
      if(!is_high) continue;
      for(int R = 1; R <= InpPivotRightBars; R++) if(candidate_price <= iHigh(_Symbol, _Period, i - R)) {is_high=false; break;}
      
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
      for(int R = 1; R <= InpPivotRightBars; R++) if(candidate_price >= iLow(_Symbol, _Period, i - R)) {is_low=false; break;}

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
