  // SynPropEA1.mq5
#property copyright "t2an1s"
#property link      "https://github.com/t2an1s/SynerProEA"
#property version   "1.05" // Updated version
#property strict
#property description "Master EA for Synergy Strategy - Prop Account"
#property script_show_inputs

#include "SynPropEA1_Dashboard.mqh" 
#include <Trade\Trade.mqh>

// --- Global Variables & Inputs ---
// File Communication Settings
input string InpCommandFileName       = "SynerProEA_Commands.csv";  // File for EA communication
input string InpSlaveEAStatusFile     = "EA2_Status.txt";           // Slave EA status file
input bool   InpUseSharedFolder       = true;                       // Use MT5 shared folder for files
input string InpMasterEAStatusFile    = "EA1_Status.txt";           // Master EA status file

// Symbol Compatibility Settings (for broker prefix/suffix handling)
input group  "=== BROKER SYMBOL COMPATIBILITY ===";
input string InpMasterSymbolOverride  = "";                         // Override master symbol (leave empty for auto _Symbol)
input string InpExpectedSlaveSymbol   = "";                         // Expected slave symbol (leave empty for auto)
input bool   InpEnableSymbolLogging   = true;                       // Enable detailed symbol compatibility logging

// Basic Trading Settings
input double InpLotSize               = 0.01;                       // Fixed lot size (if risk % disabled)
input bool   InpUseRiskPercentage     = true;                       // Enable risk-based position sizing
input double InpRiskPercentage        = 0.3;                        // Risk percentage per trade
input int    InpMagicNumber           = 12345;                      // Magic number for trade identification
input double InpStopLossBufferPips    = 2.0;                        // Extra pips added to pivot SL/TP
input bool   InpAllowNewTrades        = true;                       // Enable/disable new trade opening
input int    InpMaxSimultaneousOrders = 1;                          // Maximum simultaneous orders (1 = no pyramiding)

// Risk Management Alerts
input bool   InpEnableTargetShutdown   = true;                      // Auto-shutdown when target achieved

// Prop Challenge Settings
input double InpChallengeCostDollars    = 700.0;                    // Challenge purchase cost
input int    InpChallengePhases         = 1;                        // Number of challenge phases
input double InpTargetProfitDollars     = 10000.0;                  // Target profit to pass challenge
input double InpMaxDrawdownDollars      = 4000.0;                   // Maximum total drawdown limit
input double InpDailyDrawdownDollars    = 2000.0;                   // Daily drawdown limit
input double InpStartingBalanceOverride = 100000.0;                 // Override starting balance (0 = auto-detect)
input int    InpMinTradingDaysRequired  = 5;                        // Minimum trading days required

// Drawdown Dashboard Settings
input group  "=== DRAWDOWN DASHBOARD ===";
input double InpDailyDDLimitPct         = 5.0;                      // Daily drawdown limit for visual gauge (%)
input double InpMaxDDLimitPct           = 10.0;                     // Maximum drawdown limit for visual gauge (%)
input bool   InpShowDrawdownDashboard   = true;                     // Enable drawdown dashboard display

// Live Trade Management Settings
input bool   InpEnableDD90Alert      = true;    // Enable 90% DD alerts

// Session Filter Inputs (Trading Hours in GMT)
input group  "=== TRADING SESSIONS (GMT) ===";
input bool   InpEnableSessionFilter     = true;         // 🚨 CRITICAL: Enable session filtering (if false, trade 24/7)
input string InpMondaySession           = "08:00-16:00"; // Monday trading session
input string InpTuesdaySession          = "08:00-16:00"; // Tuesday trading session
input string InpWednesdaySession        = "08:00-16:00"; // Wednesday trading session
input string InpThursdaySession         = "08:00-16:00"; // Thursday trading session
input string InpFridaySession           = "08:00-15:00"; // Friday trading session
input string InpSaturdaySession         = "";            // Saturday trading session (empty = no trading)
input string InpSundaySession           = "";            // Sunday trading session (empty = no trading)
input string InpBrokerGMTOffset         = "+2";          // Broker time zone offset from GMT

// Market Bias Filter (Heikin-Ashi) - Updated to match Pine Script exactly
input ENUM_TIMEFRAMES InpMarketBiasTimeframe = PERIOD_CURRENT; // Market Bias Timeframe (matches ha_htf)
input int             InpHAPeriod            = 100;            // HA Period (matches ha_len)
input bool            InpUseMarketBias       = true;           // Use Market Bias (matches useMarketBias)
input bool            InpShowMarketBias      = true;           // Show Market Bias (matches show_bias)
input color           InpBullishColor        = clrLime;        // Bullish Color (matches col_bull)
input color           InpBearishColor        = clrRed;         // Bearish Color (matches col_bear)
input int             InpOscillatorPeriod    = 7;              // Oscillator Period (matches osc_len)

// Trend Strength Filter (Standard ADX) - Simplified
input bool   InpEnableADXFilter         = true;           // Enable ADX Filter
input int    InpADXPeriod               = 14;             // ADX Period
input double InpADXThreshold            = 25.0;           // ADX Threshold (above this value = trending market)

// --- Synergy Score Inputs (Updated to match Pine Script exactly) ---
input bool   InpUseSynergyScore      = true;           // Use Synergy Score (matches useSynergyScore)

// Indicator weights (matches Pine Script)
input double InpRSIWeight            = 1.0;            // RSI Weight (matches rsiWeight)
input double InpTrendWeight          = 1.0;            // MA Trend Weight (matches trendWeight)
input double InpMACDVSlopeWeight     = 1.0;            // MACDV Slope Weight (matches macdvSlopeWeight)

// Timeframe selection options (matches Pine Script)
input bool   InpUseTF5min            = true;           // 5M (matches useTF5min)
input double InpWeight_M5            = 1.0;            // Weight (matches weight_m5)
input bool   InpUseTF15min           = true;           // 15M (matches useTF15min)
input double InpWeight_M15           = 1.0;            // Weight (matches weight_m15)
input bool   InpUseTF1hour           = true;           // 1H (matches useTF1hour)
input double InpWeight_H1            = 1.0;            // Weight (matches weight_h1)

// Take Profit Method Selection
input group  "=== TAKE PROFIT SETTINGS ===";
enum ENUM_TP_METHOD
{
   TP_METHOD_PIVOT = 0,    // Use Pivot-based TP
   TP_METHOD_RR = 1        // Use Risk-Reward ratio TP
};
input ENUM_TP_METHOD InpTPMethod = TP_METHOD_PIVOT;    // Take Profit Method
input double InpRiskRewardRatio  = 1.5;               // Risk-Reward Ratio (when using RR method)

// Pivots
input int    InpPivotLookbackBars = 1000;  // Increased from 500 to 1000 for comprehensive pivot detection
input int    InpPivotLeftBars     = 6;  
input int    InpPivotRightBars    = 6;  

// Scale-Out Strategy Settings (added to match Pine Script)
input bool   InpEnableScaleOut    = true;   // "Enable Scale-Out Strategy"
input bool   InpScaleOut1Enabled  = true;   // "Enable Scale-Out" 
input double InpScaleOut1Pct      = 10.0;   // "% of TP Distance" (5-95%) - FIXED: Was 50.0, now 10.0 for 10% of TP
input double InpScaleOut1Size     = 50.0;   // "% of Position" (25, 33, 50, 66, 75)
input bool   InpScaleOut1BE       = true;   // "Set BE on Scale-Out"

// Hedging Response to Master Scale-Out Settings
input group  "=== HEDGING RESPONSE TO SCALE-OUT ===";
enum ENUM_HEDGE_SCALEOUT_STRATEGY
{
   HEDGE_SCALEOUT_NONE = 0,           // No response - let hedge run full course
   HEDGE_SCALEOUT_REDUCE = 1,         // Reduce hedge size proportionally
   HEDGE_SCALEOUT_BREAKEVEN = 2,      // Move hedge to breakeven
   HEDGE_SCALEOUT_INVERSE = 3,        // Scale out hedge when it reaches profit
   HEDGE_SCALEOUT_CLOSE_PARTIAL = 4,  // Close same percentage as master
   HEDGE_SCALEOUT_ADAPTIVE = 5        // Adaptive based on hedge P&L
};

input ENUM_HEDGE_SCALEOUT_STRATEGY InpHedgeScaleOutStrategy = HEDGE_SCALEOUT_ADAPTIVE; // Hedge Response Strategy
input double InpHedgeScaleOutReduction = 50.0;      // % Hedge Reduction (when using REDUCE strategy)
input bool   InpHedgeBreakevenOnMasterScaleOut = true; // Move Hedge to BE when Master scales out profitably
input double InpHedgeInverseTriggerPct = 10.0;      // % of Hedge TP distance for inverse scale-out
input bool   InpHedgeAdaptiveRiskReduction = true;  // Enable adaptive risk reduction
input double InpHedgeMaxRiskExposure = 2.0;         // Max risk exposure multiplier after scale-out

// BreakEven Settings
input bool   InpEnableBreakEven   = false;  // "Enable BreakEven w/o Scale-Out"  
input int    InpBETriggerPips     = 10;     // "BE Trigger (pips)"

// Visual Toggles
input bool   InpShowPivotVisuals    = true;
input color  InpPivotUpColor        = clrGreen; 
input color  InpPivotDownColor      = clrRed;   
input bool   InpShowMarketBiasVisual= true;
input color  InpMarketBiasUpColor   = C'173,216,230'; 
input color  InpMarketBiasDownColor = C'255,192,203'; 


// --- Internal Global Variables ---
int    h_adx_main; 

// Strategy Tester Mode Detection
bool   g_is_tester_mode = false;

double val_HA_Bias_Oscillator;
double prev_HA_Bias_Oscillator_Value; 
bool   biasChangedToBullish_MQL;
bool   biasChangedToBearish_MQL;

double val_ADX_Main, val_ADX_Plus, val_ADX_Minus;
double val_SynergyScore_M5, val_SynergyScore_M15, val_SynergyScore_H1;
double val_TotalSynergyScore;

PivotPoint recent_pivot_high; 
PivotPoint recent_pivot_low;  
PivotPoint g_identified_pivots_high[]; 
PivotPoint g_identified_pivots_low[];  

long   broker_time_gmt_offset_seconds;
bool   is_session_active;
static datetime g_last_session_print_time = 0; // For throttling session prints
const  int SESSION_PRINT_THROTTLE_SECONDS = 60;
static datetime g_last_closed_bar_opentime_ea1 = 0; // ADDED: For new bar detection logic, initialized to 0
datetime PrevBarTime; 
string g_ea_version_str = "1.05"; 

double   g_initial_challenge_balance_prop; 
double   g_prop_balance_at_day_start;
double   g_prop_equity_at_day_start;                  // ADDED: Critical fix for proper daily tracking
double   g_prop_highest_equity_peak;
int      g_prop_current_trading_days;
datetime g_last_day_for_daily_reset; 
datetime g_unique_trading_day_dates[]; 
int      g_min_bars_needed_for_ea = 100;
double   g_point_value; 
int      g_digits_value; 
int      g_ea_open_positions_count = 0;    // Count of positions by this EA on this symbol
ENUM_ORDER_TYPE g_ea_open_positions_type = WRONG_VALUE; // Direction of existing EA positions

// Position monitoring for SL/TP changes
struct PositionState
{
   ulong ticket;
   double sl;
   double tp;
   datetime last_check;
};
PositionState g_monitored_positions[];

// --- Slave EA Status Global Variables ---
double   g_slave_balance = 0.0;
double   g_slave_equity = 0.0;
double   g_slave_daily_pnl = 0.0;
long     g_slave_account_number = 0;

// --- Drawdown Dashboard Global Variables ---
double   g_all_time_high = 0.0;
double   g_daily_high = 0.0;
int      g_last_day_dd = 0;
string   g_slave_account_currency = "";
string   g_slave_status_text = "Slave N/A";
bool     g_slave_is_connected = false;
datetime g_slave_last_update_in_file = 0;       // Timestamp from within the slave status file
datetime g_slave_last_update_processed_time = 0; // Last time EA1 successfully processed the slave file
int      g_slave_status_file_handle = INVALID_HANDLE;
int      g_common_command_file_handle = INVALID_HANDLE;
string   g_csv_delimiter = ","; // Using comma as per initial plan, ensure consistency with slave

// New globals for additional slave data
double   g_slave_open_volume = 0.0;
int      g_slave_leverage = 0;
string   g_slave_server = "N/A";

// --- New Global Variables for Live Trade Management ---
static bool g_daily_dd_90_alert_triggered = false;    // Track if 90% daily DD alert has been sent
static bool g_max_dd_90_alert_triggered = false;      // Track if 90% max DD alert has been sent  
static bool g_target_achieved_shutdown = false;       // Track if EA has been shut down due to target achievement
static datetime g_last_alert_time = 0;                // Prevent spam alerts

// --- Hedge Loss Tracking Variables ---
static double g_hedge_pnl = 0.0;                      // Current hedge P&L
static double g_hedge_loss_percentage = 0.0;          // Hedge loss as % of challenge cost
static datetime g_last_hedge_data_update = 0;         // Last time hedge data was extracted

// --- Scale-Out Tracking Variables (added to match Pine Script) ---
static bool g_scaleOut1LongTriggered = false;   // Track if scale-out 1 triggered for long positions
static bool g_scaleOut1ShortTriggered = false;  // Track if scale-out 1 triggered for short positions  
static bool g_beAppliedLong = false;             // Track if breakeven applied to long positions
static bool g_beAppliedShort = false;            // Track if breakeven applied to short positions
static double g_lastEntryLots = 0.0;             // Store last entry lot size for scale-out calculations
static double g_pivotStopLongEntry = 0.0;        // Store long entry stop level
static double g_pivotTpLongEntry = 0.0;          // Store long entry TP level  
static double g_pivotStopShortEntry = 0.0;       // Store short entry stop level
static double g_pivotTpShortEntry = 0.0;         // Store short entry TP level

// --- Debug Message Throttling Variables ---
static datetime g_last_pivot_debug_log_time = 0;
static datetime g_last_slave_debug_log_time = 0;
static datetime g_last_master_debug_log_time = 0;
const int DEBUG_PRINT_THROTTLE_SECONDS = 60; // 1 minute throttling for debug messages

// --- Dashboard Variables (for external access) ---
double g_challenge_cost = 700.0;                      // Challenge cost for dashboard

// --- Daily Reset Configuration (added to match user specification) ---
input group  "=== DAILY TRACKING SETTINGS ===";
input int    InpDailyResetHour = 0;                  // Hour for daily reset (0-23)
input int    InpDailyResetMinute = 1;                // Minute for daily reset (1 for 00:01-23:59 period)
input bool   InpEnableDailyTrackingLogs = true;     // Enable detailed daily tracking logs

// --- EA2 SAFETY VERIFICATION SYSTEM (CRITICAL SAFETY FEATURE) ---
input group  "=== EA2 SAFETY VERIFICATION ===";
input bool   InpRequireEA2Verification = true;        // REQUIRE EA2 verification before trading
input int    InpEA2VerificationTimeoutSec = 30;       // Timeout for EA2 response (seconds)
input int    InpMinEA2StatusUpdates = 3;              // Minimum status updates required from EA2
input bool   InpEnableEA2SafetyLogging = true;        // Enable detailed EA2 safety logging

// --- EA2 VERIFICATION TRACKING VARIABLES ---
static bool g_ea2_is_verified = false;                // EA2 verification status
static bool g_ea2_is_connected = false;               // EA2 connection status
static bool g_ea2_is_receive_mode = false;            // EA2 in receive mode
static int g_ea2_status_update_count = 0;             // Count of status updates received
static datetime g_last_ea2_status_time = 0;           // Last EA2 status update time
static datetime g_ea2_verification_start_time = 0;    // When verification process started
static string g_ea2_last_status_message = "";         // Last status message from EA2
static bool g_trading_blocked_by_safety = true;       // Trading blocked until EA2 verified

// EA2 verification structure
struct EA2VerificationStatus
{
    bool is_verified;                    // Overall verification status
    bool is_connected;                   // EA2 connection confirmed
    bool is_receive_mode;               // EA2 ready to receive commands
    bool has_minimum_updates;           // Received minimum status updates
    bool response_time_ok;              // Response time within timeout
    datetime last_status_time;          // Last status update timestamp
    int status_update_count;            // Number of status updates received
    string last_message;                // Last status message
    string verification_failure_reason; // Reason if verification failed
};

//+------------------------------------------------------------------+
// Live Trade Management Functions
//+------------------------------------------------------------------+

// Function to close all open positions for this EA
bool CloseAllPositions(string reason = "System Shutdown")
{
    bool all_closed = true;
    int total_positions = PositionsTotal();
    int positions_closed = 0;
    
    Print("CloseAllPositions: Starting closure of all EA positions. Reason: ", reason);
    
    for(int i = total_positions - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
               PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                CTrade trade;
                bool close_result = trade.PositionClose(ticket);
                
                if(close_result)
                {
                    positions_closed++;
                    PrintFormat("CloseAllPositions: Successfully closed position #%d", ticket);
                    
                    // Send close command to slave EA
                    WriteCommandToSlaveFile("CLOSE_HEDGE", ticket, _Symbol);
                }
                else
                {
                    all_closed = false;
                    PrintFormat("CloseAllPositions: Failed to close position #%d. Error: %d", 
                              ticket, GetLastError());
                }
            }
        }
    }
    
    PrintFormat("CloseAllPositions: Completed. Positions closed: %d, All closed: %s", 
                positions_closed, all_closed ? "YES" : "NO");
    
    return all_closed;
}

// Function to check for 90% DD alerts
void CheckDrawdownAlerts()
{
    if(!InpEnableDD90Alert) return;
    
    // Prevent spam alerts - only check once per 60 seconds (changed from 15)
    if(TimeCurrent() - g_last_alert_time < 60) return;
    
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // ENHANCED VALIDATION: Add safety checks for daily DD alerts
    
    // Check 90% of Daily DD limit
    double daily_dd_floor = g_prop_balance_at_day_start - InpDailyDrawdownDollars;
    double daily_dd_90_threshold = g_prop_balance_at_day_start - (InpDailyDrawdownDollars * 0.9);
    double daily_dd_current = g_prop_balance_at_day_start - current_equity;
    
    // Safety Check 1: Validate daily balance start is reasonable
    if(g_prop_balance_at_day_start < 1000.0)
    {
        PrintFormat("DD ALERT CHECK: Daily balance start %.2f seems too low. Skipping daily DD check.", g_prop_balance_at_day_start);
    }
    else if(!g_daily_dd_90_alert_triggered && current_equity <= daily_dd_90_threshold)
    {
        // Additional validation: Ensure we actually have a significant daily loss
        if(daily_dd_current > (InpDailyDrawdownDollars * 0.8)) // Only alert if we're truly near the limit
        {
            g_daily_dd_90_alert_triggered = true;
            g_last_alert_time = TimeCurrent();
            
            string alert_msg = StringFormat("⚠️ CRITICAL: 90%% Daily DD Reached! Equity: %.2f, Start: %.2f, Loss: %.2f, Threshold: %.2f, Floor: %.2f", 
                                           current_equity, g_prop_balance_at_day_start, daily_dd_current, daily_dd_90_threshold, daily_dd_floor);
            Print(alert_msg);
            Alert(alert_msg);
            
            // Send message to slave EA via comment field
            WriteCommandToSlaveFile("DAILY_DD_90_ALERT", 0, _Symbol);
            
            // Log detailed information for debugging
            PrintFormat("DAILY DD ALERT DETAILS: StartBalance=%.2f, CurrentEquity=%.2f, DDLimit=%.2f, Loss=%.2f, Threshold=%.2f",
                       g_prop_balance_at_day_start, current_equity, InpDailyDrawdownDollars, daily_dd_current, daily_dd_90_threshold);
        }
        else
        {
            PrintFormat("DD CHECK: Daily DD 90%% threshold reached but loss %.2f < 80%% of limit %.2f. Preventing false alert.",
                       daily_dd_current, InpDailyDrawdownDollars * 0.8);
        }
    }
    
    // ENHANCED VALIDATION: Add safety checks for max DD alerts
    
    // Check 90% of Max DD limit  
    double max_dd_floor = g_prop_highest_equity_peak - InpMaxDrawdownDollars;
    double max_dd_90_threshold = g_prop_highest_equity_peak - (InpMaxDrawdownDollars * 0.9);
    double max_dd_current = g_prop_highest_equity_peak - current_equity;
    
    // Safety Check 2: Validate equity peak is reasonable
    if(g_prop_highest_equity_peak < 1000.0)
    {
        PrintFormat("DD ALERT CHECK: Equity peak %.2f seems too low. Skipping max DD check.", g_prop_highest_equity_peak);
    }
    else if(!g_max_dd_90_alert_triggered && current_equity <= max_dd_90_threshold)
    {
        // Additional validation: Ensure we actually have a significant drawdown from peak
        if(max_dd_current > (InpMaxDrawdownDollars * 0.8)) // Only alert if we're truly near the limit
        {
            g_max_dd_90_alert_triggered = true;
            g_last_alert_time = TimeCurrent();
            
            string alert_msg = StringFormat("⚠️ CRITICAL: 90%% Max DD Reached! Equity: %.2f, Peak: %.2f, Drawdown: %.2f, Threshold: %.2f, Floor: %.2f", 
                                           current_equity, g_prop_highest_equity_peak, max_dd_current, max_dd_90_threshold, max_dd_floor);
            Print(alert_msg);
            Alert(alert_msg);
            
            // Send message to slave EA via comment field
            WriteCommandToSlaveFile("MAX_DD_90_ALERT", 0, _Symbol);
            
            // Log detailed information for debugging
            PrintFormat("MAX DD ALERT DETAILS: EquityPeak=%.2f, CurrentEquity=%.2f, DDLimit=%.2f, Drawdown=%.2f, Threshold=%.2f",
                       g_prop_highest_equity_peak, current_equity, InpMaxDrawdownDollars, max_dd_current, max_dd_90_threshold);
        }
        else
        {
            PrintFormat("DD CHECK: Max DD 90%% threshold reached but drawdown %.2f < 80%% of limit %.2f. Preventing false alert.",
                       max_dd_current, InpMaxDrawdownDollars * 0.8);
        }
    }
    
    // ENHANCED LOGGING: Log current DD status periodically (every 5 minutes during risky periods)
    static datetime last_dd_status_log = 0;
    if(TimeCurrent() - last_dd_status_log > 300) // 5 minutes
    {
        if(daily_dd_current > (InpDailyDrawdownDollars * 0.5) || max_dd_current > (InpMaxDrawdownDollars * 0.5))
        {
            PrintFormat("DD STATUS: Daily Loss: %.2f/%.2f (%.1f%%), Max DD: %.2f/%.2f (%.1f%%), Equity: %.2f",
                       daily_dd_current, InpDailyDrawdownDollars, (daily_dd_current/InpDailyDrawdownDollars)*100,
                       max_dd_current, InpMaxDrawdownDollars, (max_dd_current/InpMaxDrawdownDollars)*100,
                       current_equity);
            last_dd_status_log = TimeCurrent();
        }
    }
}

// Function to check for target achievement and shutdown
bool CheckTargetAchievementShutdown()
{
    if(!InpEnableTargetShutdown || g_target_achieved_shutdown) return false;
    
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double target_equity = g_initial_challenge_balance_prop + InpTargetProfitDollars;
    double actual_profit = current_equity - g_initial_challenge_balance_prop;
    
    // ENHANCED VALIDATION: Add safety checks to prevent false triggers
    
    // Add throttling for target check logs to prevent spam
    static datetime last_target_check_log = 0;
    const int TARGET_CHECK_LOG_THROTTLE_SECONDS = 60; // Log only once per minute
    
    // Safety Check 1: Ensure we actually have positive profit
    if(actual_profit <= 0.0)
    {
        // Only log this message once per minute to prevent spam
        if(TimeCurrent() - last_target_check_log >= TARGET_CHECK_LOG_THROTTLE_SECONDS)
        {
            PrintFormat("TARGET CHECK: Current profit %.2f <= 0. No target achieved (Equity: %.2f, Initial: %.2f)", 
                       actual_profit, current_equity, g_initial_challenge_balance_prop);
            last_target_check_log = TimeCurrent();
        }
        return false;
    }
    
    // Safety Check 2: Ensure target is reasonable (at least 5% of initial balance)
    double min_reasonable_target = g_initial_challenge_balance_prop * 0.05; // 5% minimum
    if(InpTargetProfitDollars < min_reasonable_target)
    {
        PrintFormat("TARGET CHECK: Target %.2f seems too low (< 5%% of %.2f = %.2f). Preventing false trigger.", 
                   InpTargetProfitDollars, g_initial_challenge_balance_prop, min_reasonable_target);
        return false;
    }
    
    // Safety Check 3: Ensure initial balance setting is reasonable
    if(g_initial_challenge_balance_prop < 1000.0)
    {
        PrintFormat("TARGET CHECK: Initial balance %.2f seems too low. Check InpStartingBalanceOverride setting.", 
                   g_initial_challenge_balance_prop);
        return false;
    }
    
    // ENHANCED LOGGING: Log the target check calculation only once per minute to prevent spam
    if(TimeCurrent() - last_target_check_log >= TARGET_CHECK_LOG_THROTTLE_SECONDS)
    {
        PrintFormat("TARGET CHECK: Current Equity: %.2f, Initial Balance: %.2f, Target: %.2f (%.2f profit needed), Actual Profit: %.2f", 
                   current_equity, g_initial_challenge_balance_prop, target_equity, InpTargetProfitDollars, actual_profit);
        last_target_check_log = TimeCurrent();
    }
    
    // Main target check with enhanced validation
    if(current_equity >= target_equity && actual_profit >= InpTargetProfitDollars)
    {
        g_target_achieved_shutdown = true;
        
        string shutdown_msg = StringFormat("🎯 TARGET ACHIEVED! Equity: %.2f, Target: %.2f, Profit: %.2f/%.2f. Closing all positions and shutting down EA.", 
                                          current_equity, target_equity, actual_profit, InpTargetProfitDollars);
        Print(shutdown_msg);
        Alert(shutdown_msg);
        
        // Log all the key values for debugging
        PrintFormat("TARGET ACHIEVED DETAILS: Initial=%.2f, Current=%.2f, Target=%.2f, Profit=%.2f, InpTargetProfit=%.2f, InpStartOverride=%.2f",
                   g_initial_challenge_balance_prop, current_equity, target_equity, actual_profit, 
                   InpTargetProfitDollars, InpStartingBalanceOverride);
        
        // Close all positions
        bool all_closed = CloseAllPositions("Target Achieved - Profit Taking");
        
        // Send shutdown message to slave EA
        WriteCommandToSlaveFile("TARGET_ACHIEVED", 0, _Symbol);
        
        // Update dashboard with final status
        Dashboard_UpdateStatus("TARGET ACHIEVED - EA SHUTDOWN", false);
        
        return true;
    }
    
    return false;
}

// Function to reset target achievement flag (for debugging/recovery)
void ResetTargetShutdown()
{
    g_target_achieved_shutdown = false;
    Print("TARGET SHUTDOWN FLAG RESET - EA can now trade again if other conditions are met");
}

// Function to reset daily alerts on new trading day
void ResetDailyAlerts()
{
    g_daily_dd_90_alert_triggered = false;
    PrintFormat("Daily DD 90%% alert status reset for new trading day. New daily start balance: %.2f", g_prop_balance_at_day_start);
}

// Function to reset all DD alerts (for debugging/recovery)
void ResetAllDDAlerts()
{
    g_daily_dd_90_alert_triggered = false;
    g_max_dd_90_alert_triggered = false;
    g_last_alert_time = 0;
    Print("ALL DD ALERT FLAGS RESET - Daily and Max DD alerts can now trigger again if thresholds are reached");
}

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
void UpdateMonitoredPositions()
  {
   // Get current EA positions
   int total_positions = PositionsTotal();
   
   // Temporary array to store current positions
   PositionState current_positions[];
   int current_count = 0;
   
   for(int i = 0; i < total_positions; i++)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
        {
         if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
            PositionGetString(POSITION_SYMBOL) == _Symbol)
           {
            ArrayResize(current_positions, current_count + 1);
            current_positions[current_count].ticket = ticket;
            current_positions[current_count].sl = PositionGetDouble(POSITION_SL);
            current_positions[current_count].tp = PositionGetDouble(POSITION_TP);
            current_positions[current_count].last_check = TimeCurrent();
            current_count++;
           }
        }
     }
   
   // Check for SL/TP changes in existing monitored positions
   for(int j = 0; j < ArraySize(g_monitored_positions); j++)
     {
      bool position_still_exists = false;
      for(int k = 0; k < current_count; k++)
        {
         if(current_positions[k].ticket == g_monitored_positions[j].ticket)
           {
            position_still_exists = true;
            
            // Check for SL/TP changes
            if(current_positions[k].sl != g_monitored_positions[j].sl || 
               current_positions[k].tp != g_monitored_positions[j].tp)
              {
               PrintFormat("MonitorPositions: SL/TP change detected for position #%d. Old SL/TP: %.5f/%.5f -> New: %.5f/%.5f",
                          current_positions[k].ticket, g_monitored_positions[j].sl, g_monitored_positions[j].tp,
                          current_positions[k].sl, current_positions[k].tp);
               
               // Send MODIFY_HEDGE command
               WriteCommandToSlaveFile("MODIFY_HEDGE", current_positions[k].ticket, _Symbol, 0, 0, 
                                      current_positions[k].tp, current_positions[k].sl);
              }
            break;
           }
        }
     }
   
   // Update monitored positions array with current state
   ArrayFree(g_monitored_positions);
   ArrayResize(g_monitored_positions, current_count);
   for(int m = 0; m < current_count; m++)
     {
      g_monitored_positions[m] = current_positions[m];
     }
  }

//+------------------------------------------------------------------+
double GetPipToPointsMultiplier()
  {
   string sym = _Symbol;
   bool isForexOrMetal = (StringFind(sym, "USD") >= 0 || StringFind(sym, "EUR") >= 0 || StringFind(sym, "GBP") >= 0 ||
                         StringFind(sym, "JPY") >= 0 || StringFind(sym, "AUD") >= 0 || StringFind(sym, "NZD") >= 0 ||
                         StringFind(sym, "CAD") >= 0 || StringFind(sym, "CHF") >= 0 || StringFind(sym, "XAU") >= 0 ||
                         StringFind(sym, "XAG") >= 0);
   
   bool isCrypto = (StringFind(sym, "BTC") >= 0 || StringFind(sym, "ETH") >= 0 || 
                   StringFind(sym, "XRP") >= 0 || StringFind(sym, "ADA") >= 0 ||
                   StringFind(sym, "LTC") >= 0 || StringFind(sym, "DOT") >= 0 ||
                   StringFind(sym, "LINK") >= 0 || StringFind(sym, "BNB") >= 0 ||
                   StringFind(sym, "SOL") >= 0 || StringFind(sym, "AVAX") >= 0);

   if(isForexOrMetal && (g_digits_value == 5 || g_digits_value == 3))
     {
      return 10.0;
     }
   else if(isCrypto)
     {
      // Crypto typically uses 1.0 multiplier as they don't follow traditional pip structure
      return 1.0;
     }
   return 1.0;
  }

//+------------------------------------------------------------------+
void CalculateGMTOffset()
  {
   string offset_str = InpBrokerGMTOffset;
   PrintFormat("CalculateGMTOffset: Raw InpBrokerGMTOffset = '%s'", offset_str);
   StringReplace(offset_str, "GMT", "");
   StringReplace(offset_str, " ", ""); 
   broker_time_gmt_offset_seconds = (long)StringToInteger(offset_str) * 3600;
   PrintFormat("CalculateGMTOffset: Parsed offset_str = '%s', broker_time_gmt_offset_seconds = %d", offset_str, broker_time_gmt_offset_seconds);
  }

//+------------------------------------------------------------------+
bool IsInTradingSession()
  {
   // If session filtering is disabled, always allow trading
   if(!InpEnableSessionFilter)
     {
      bool should_print_bypass = (TimeCurrent() - g_last_session_print_time >= SESSION_PRINT_THROTTLE_SECONDS);
      if(should_print_bypass)
        {
         PrintFormat("⚠️ IsInTradingSession: SESSION FILTERING DISABLED - Trading 24/7 allowed");
         g_last_session_print_time = TimeCurrent();
        }
      return true;
     }

   datetime current_broker_dt = TimeCurrent(); 
   datetime current_gmt_timestamp = (datetime)(current_broker_dt - broker_time_gmt_offset_seconds); 
   MqlDateTime gmt_time_struct;
   TimeToStruct(current_gmt_timestamp, gmt_time_struct);

   bool should_print_session_details = (TimeCurrent() - g_last_session_print_time >= SESSION_PRINT_THROTTLE_SECONDS);

   int day_of_week = gmt_time_struct.day_of_week; // 0=Sun, 1=Mon, ..., 6=Sat
   int current_hour_gmt = gmt_time_struct.hour;
   int current_min_gmt = gmt_time_struct.min;

   // Get the session string for current day
   string session_str = "";
   string day_name = "";
   switch(day_of_week)
     {
      case 0: session_str = InpSundaySession;    day_name = "Sunday"; break;
      case 1: session_str = InpMondaySession;    day_name = "Monday"; break;
      case 2: session_str = InpTuesdaySession;   day_name = "Tuesday"; break;
      case 3: session_str = InpWednesdaySession; day_name = "Wednesday"; break;
      case 4: session_str = InpThursdaySession;  day_name = "Thursday"; break;
      case 5: session_str = InpFridaySession;    day_name = "Friday"; break;
      case 6: session_str = InpSaturdaySession;  day_name = "Saturday"; break;
     }

   if(should_print_session_details)
     {
      PrintFormat("IsInTradingSession: Filter ENABLED=%s | %s GMT %02d:%02d - Session: '%s' | Broker Time: %s | GMT Offset: %d sec", 
                    InpEnableSessionFilter ? "YES" : "NO", day_name, current_hour_gmt, current_min_gmt, session_str,
                    TimeToString(current_broker_dt, TIME_DATE|TIME_SECONDS), broker_time_gmt_offset_seconds);
     }

   // If no session defined for this day, no trading
   if(session_str == "")
     {
      if(should_print_session_details)
        {
         PrintFormat("IsInTradingSession: RESULT = false (%s - No session defined)", day_name);
         g_last_session_print_time = TimeCurrent();
        }
      return false;
     }

   // Parse session time (format: "HH:MM-HH:MM")
   if(StringFind(session_str, "-") <= 0)
     {
      if(should_print_session_details)
        {
         PrintFormat("IsInTradingSession: RESULT = false (%s - Invalid session format: '%s')", day_name, session_str);
         g_last_session_print_time = TimeCurrent();
        }
      return false;
     }

   string times[];
   if(StringSplit(session_str, '-', times) != 2)
     {
      if(should_print_session_details)
        {
         PrintFormat("IsInTradingSession: RESULT = false (%s - Session parse error: '%s')", day_name, session_str);
         g_last_session_print_time = TimeCurrent();
        }
      return false;
     }

   // Parse start time
   string start_hm[];
   if(StringSplit(times[0], ':', start_hm) != 2)
     {
      if(should_print_session_details)
        {
         PrintFormat("IsInTradingSession: RESULT = false (%s - Start time parse error: '%s')", day_name, times[0]);
         g_last_session_print_time = TimeCurrent();
        }
      return false;
     }

   // Parse end time  
   string end_hm[];
   if(StringSplit(times[1], ':', end_hm) != 2)
     {
      if(should_print_session_details)
        {
         PrintFormat("IsInTradingSession: RESULT = false (%s - End time parse error: '%s')", day_name, times[1]);
         g_last_session_print_time = TimeCurrent();
        }
      return false;
     }

   int start_h = (int)StringToInteger(start_hm[0]);
   int start_m = (int)StringToInteger(start_hm[1]);
   int end_h = (int)StringToInteger(end_hm[0]);
   int end_m = (int)StringToInteger(end_hm[1]);

   // Convert to minutes for easy comparison
   int current_time_mins = current_hour_gmt * 60 + current_min_gmt;
   int start_time_mins = start_h * 60 + start_m;
   int end_time_mins = end_h * 60 + end_m;

   bool in_session = false;

   // Handle overnight sessions (e.g., "22:00-06:00")
   if(end_time_mins < start_time_mins)
     {
      // Overnight session: active if after start OR before end
      in_session = (current_time_mins >= start_time_mins || current_time_mins < end_time_mins);
     }
   else
     {
      // Normal session: active if between start and end
      in_session = (current_time_mins >= start_time_mins && current_time_mins < end_time_mins);
     }

   if(should_print_session_details)
     {
      PrintFormat("IsInTradingSession: %s %02d:%02d GMT - Session %02d:%02d-%02d:%02d = %s", 
                    day_name, current_hour_gmt, current_min_gmt, start_h, start_m, end_h, end_m, 
                    in_session ? "ACTIVE" : "INACTIVE");
      PrintFormat("  └─ Time comparison: Current=%d mins, Start=%d mins, End=%d mins, Overnight=%s", 
                    current_time_mins, start_time_mins, end_time_mins, 
                    (end_time_mins < start_time_mins) ? "YES" : "NO");
      g_last_session_print_time = TimeCurrent();
     }

   return in_session;
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
   PrintFormat("IdentifyPivotsForVisuals: Found %d high pivots and %d low pivots over %d lookback bars.", 
               ArraySize(g_identified_pivots_high), ArraySize(g_identified_pivots_low), lookback_visual);
  }

//+------------------------------------------------------------------+
double CalculateLotSize(double stop_loss_distance_points) 
  {
   double lot_size = InpLotSize; 

   if(InpUseRiskPercentage)
     {
      if(stop_loss_distance_points <= 0)
        {
         Print("CalculateLotSize: Cannot calculate risk-based lot size. Stop loss distance is zero or negative: ", stop_loss_distance_points);
         return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); 
        }

      double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
      double risk_amount = account_balance * (InpRiskPercentage / 100.0);
      
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
                  account_balance, InpRiskPercentage, risk_amount, stop_loss_distance_points, value_per_point_one_lot, loss_per_lot_at_sl, lot_size);
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
double CalculateTakeProfit(int signal_type, double entry_price, double sl_price = 0.0)
  {
   if(entry_price == 0.0)
     {
      Print("TP Calc: Entry price is 0.0. Cannot calculate TP.");
      return 0.0;
     }

   double tp_price = 0.0;
   double pip_to_points_multiplier = GetPipToPointsMultiplier();
   double buffer_points_price_units = InpStopLossBufferPips * pip_to_points_multiplier * g_point_value;

   // Choose TP calculation method based on user selection
   if(InpTPMethod == TP_METHOD_RR) // Risk-Reward ratio method
     {
      // Calculate TP based on RR ratio using SL distance
      if(sl_price == 0.0)
        {
         // If SL not provided, calculate it first for RR method
         sl_price = CalculateStopLoss(signal_type, entry_price);
         if(sl_price == 0.0)
           {
            PrintFormat("TP Calc (RR): Cannot calculate RR-based TP without valid SL. Entry: %.5f", entry_price);
            return 0.0;
           }
        }
      
      double sl_distance = MathAbs(entry_price - sl_price);
      double tp_distance = sl_distance * InpRiskRewardRatio;
      
      if(signal_type == 1) // BUY
        {
         tp_price = entry_price + tp_distance;
         PrintFormat("TP Calc (BUY-RR): Entry %.5f, SL %.5f, RR %.2f, TP: %.5f (SL Dist: %.1f pts, TP Dist: %.1f pts)",
                     entry_price, sl_price, InpRiskRewardRatio, tp_price, 
                     sl_distance/g_point_value, tp_distance/g_point_value);
        }
      else if(signal_type == -1) // SELL
        {
         tp_price = entry_price - tp_distance;
         PrintFormat("TP Calc (SELL-RR): Entry %.5f, SL %.5f, RR %.2f, TP: %.5f (SL Dist: %.1f pts, TP Dist: %.1f pts)",
                     entry_price, sl_price, InpRiskRewardRatio, tp_price, 
                     sl_distance/g_point_value, tp_distance/g_point_value);
        }
     }
   else // Pivot-based method (default)
     {
      if(signal_type == 1) // BUY - Use recent_pivot_high as TP
        {
         if(recent_pivot_high.price > 0 && recent_pivot_high.price > entry_price)
           {
            tp_price = recent_pivot_high.price + buffer_points_price_units;
            PrintFormat("TP Calc (BUY-Pivot): Using Pivot High %.5f (Time: %s), Buffer %.5f. TP: %.5f", 
                        recent_pivot_high.price, TimeToString(recent_pivot_high.time), buffer_points_price_units, tp_price);
           }
         else
           {
            PrintFormat("TP Calc (BUY-Pivot): Pivot High not valid (Price: %.5f, Time: %s) or not above entry (%.5f). No TP calculated.",
                        recent_pivot_high.price, TimeToString(recent_pivot_high.time), entry_price);
            return 0.0; 
           }
        }
      else if(signal_type == -1) // SELL - Use recent_pivot_low as TP
        {
         if(recent_pivot_low.price > 0 && recent_pivot_low.price < entry_price)
           {
            tp_price = recent_pivot_low.price - buffer_points_price_units;
            PrintFormat("TP Calc (SELL-Pivot): Using Pivot Low %.5f (Time: %s), Buffer %.5f. TP: %.5f", 
                        recent_pivot_low.price, TimeToString(recent_pivot_low.time), buffer_points_price_units, tp_price);
           }
         else
           {
            PrintFormat("TP Calc (SELL-Pivot): Pivot Low not valid (Price: %.5f, Time: %s) or not below entry (%.5f). No TP calculated.",
                        recent_pivot_low.price, TimeToString(recent_pivot_low.time), entry_price);
            return 0.0; 
           }
        }
     }

   if(signal_type != 1 && signal_type != -1)
     {
      Print("TP Calc: Invalid signal_type provided: ", signal_type);
      return 0.0;
     }

   if(tp_price != 0.0)
     {
      double min_tp_distance_points = 1.0 * pip_to_points_multiplier; 
      double current_tp_distance_points = MathAbs(tp_price - entry_price) / g_point_value;

      if (g_point_value > 0 && current_tp_distance_points < min_tp_distance_points) { 
          PrintFormat("TP Calc (%s): Calculated TP %.5f (Dist: %.1f pts) is too close to entry %.5f (MinDist: %.1f pts). Invalidating TP.", 
                      (signal_type == 1 ? "BUY" : "SELL"), tp_price, current_tp_distance_points, entry_price, min_tp_distance_points);
          return 0.0; 
      }
      
      tp_price = NormalizeDouble(tp_price, g_digits_value);
      
      string method_str = (InpTPMethod == TP_METHOD_RR) ? "RR-based" : "Pivot-based";
      PrintFormat("TP Calc (%s): Entry %.5f, %s TP: %.5f (Distance: %.1f points)",
                  (signal_type == 1 ? "BUY" : "SELL"), entry_price, method_str, tp_price, current_tp_distance_points);
     }
   return tp_price;
  }

//+------------------------------------------------------------------+
bool OpenTrade(int signal_type, double lot_size, double sl_price, double tp_price, string comment)
  {
   // =====================================================================
   // CRITICAL SAFETY CHECK: EA2 VERIFICATION (BLOCKS ALL TRADING)
   // =====================================================================
   if(!IsTradingAllowedBySafety())
   {
       PrintFormat("🚫 CRITICAL SAFETY BLOCK: Trade attempt REJECTED - EA2 not verified");
       PrintFormat("   📋 Rejected Trade: %s, Lot: %.2f, SL: %.5f, TP: %.5f", 
                  (signal_type == 1 ? "BUY" : "SELL"), lot_size, sl_price, tp_price);
       PrintFormat("   ⚠️  REASON: EA2 must be running and verified before any trades are allowed");
       LogEA2SafetyStatus(); // Force log current status for debugging
       return false;
   }
   
   string command_type = (signal_type == 1) ? "OPEN_LONG" : "OPEN_SHORT";
   if(!VerifyEA2ReadyForCommand(command_type, 0))
   {
       PrintFormat("🚫 COMMAND VERIFICATION FAILED: %s trade blocked", command_type);
       return false;
   }
   
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
   request.deviation = 3; // CHANGED: Was InpSlippage 
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
   double min_stop_level_points = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double min_stop_level_price_units = min_stop_level_points * g_point_value;

   // DIAGNOSTIC: Log broker constraints
   PrintFormat("OpenTrade DIAGNOSIS: Broker Min Stop Level: %.0f points (%.5f price units), Current Price: %.5f", 
               min_stop_level_points, min_stop_level_price_units, current_price_for_check);
   PrintFormat("OpenTrade DIAGNOSIS: Requested SL: %.5f, TP: %.5f", request.sl, request.tp);
   
   if(request.sl != 0 && g_point_value > 0) // Check g_point_value to prevent division by zero if not initialized
     {
      double sl_distance = MathAbs(current_price_for_check - request.sl);
      PrintFormat("OpenTrade DIAGNOSIS: SL distance from price: %.5f (%.1f points), Min required: %.5f", 
                  sl_distance, sl_distance/g_point_value, min_stop_level_price_units);
                  
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
      // DIAGNOSTIC: Check what the broker actually set vs what we requested
      // Need to find the position by magic and symbol since result.order is order ticket not position ticket
      int total_positions = PositionsTotal();
      bool position_found = false;
      for(int i = 0; i < total_positions; i++)
        {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket))
           {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
               PositionGetString(POSITION_SYMBOL) == _Symbol)
              {
               double actual_sl = PositionGetDouble(POSITION_SL);
               double actual_tp = PositionGetDouble(POSITION_TP);
               double actual_open = PositionGetDouble(POSITION_PRICE_OPEN);
               
               PrintFormat("OpenTrade DIAGNOSIS - BROKER RESULT: Position #%d (from Order #%d)", ticket, result.order);
               PrintFormat("OpenTrade DIAGNOSIS - REQUESTED: Entry=%.5f, SL=%.5f, TP=%.5f", 
                           request.price, request.sl, request.tp);
               PrintFormat("OpenTrade DIAGNOSIS - ACTUAL: Entry=%.5f, SL=%.5f, TP=%.5f", 
                           actual_open, actual_sl, actual_tp);
               
               if(MathAbs(actual_sl - request.sl) > g_point_value)
                 {
                  PrintFormat("⚠️ BROKER MODIFIED SL: Requested %.5f -> Actual %.5f (Diff: %.1f points)", 
                              request.sl, actual_sl, MathAbs(actual_sl - request.sl)/g_point_value);
                 }
               if(MathAbs(actual_tp - request.tp) > g_point_value)
                 {
                  PrintFormat("⚠️ BROKER MODIFIED TP: Requested %.5f -> Actual %.5f (Diff: %.1f points)", 
                              request.tp, actual_tp, MathAbs(actual_tp - request.tp)/g_point_value);
                 }
               position_found = true;
               break;
              }
           }
        }
      if(!position_found)
        {
         PrintFormat("OpenTrade DIAGNOSIS: Could not find position for order #%d to verify SL/TP", result.order);
        }
      
      AddUniqueTradingDay(TimeCurrent());
      // g_ea_open_positions_count is updated by UpdateEAOpenPositionsState() at start of OnTick
      
      // --- Store entry details for scale-out tracking (added to match Pine Script) ---
      g_lastEntryLots = lot_size;
      if(signal_type == 1) // LONG
        {
         g_pivotStopLongEntry = request.sl;
         g_pivotTpLongEntry = request.tp;
        }
      else if(signal_type == -1) // SHORT  
        {
         g_pivotStopShortEntry = request.sl;
         g_pivotTpShortEntry = request.tp;
        }
      ResetScaleOutFlags(); // Reset scale-out tracking for new trade
      
      // --- Write command to slave EA ---
      string cmd_type = (request.type == ORDER_TYPE_BUY) ? "OPEN_LONG" : "OPEN_SHORT";
      WriteCommandToSlaveFile(cmd_type, result.order, _Symbol, lot_size, result.price, request.sl, request.tp);
      // --- End write command ---
      
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   // Detect if running in Strategy Tester
   g_is_tester_mode = MQLInfoInteger(MQL_TESTER);
   if(g_is_tester_mode)
   {
       Print("Strategy Tester Mode Detected - Bypassing slave EA dependencies");
   }

   // PrevBarTime = 0; // REMOVED Old new-bar time variable initialization
   g_last_closed_bar_opentime_ea1 = 0; // Explicitly initialize, though static defaults to 0
   CalculateGMTOffset();
   
   // Initialize is_session_active early for the first status file write
   is_session_active = IsInTradingSession(); 

   // Write initial master status file promptly
   // Values for indicators might be defaults at this stage, but the file will exist.
   WriteMasterStatusFile(); 

   // Removed shared path logic, FILE_COMMON handles this.
   Print("File operations for inter-EA communication will use the common shared directory (FILE_COMMON).");

   g_point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   g_digits_value = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_ea_version_str = "1.05"; 

   h_adx_main = iADX(_Symbol, _Period, InpADXPeriod);
   if(h_adx_main == INVALID_HANDLE)
     {
      Print("Error creating ADX indicator handle. Error code: ", GetLastError());
      return(INIT_FAILED);
     }
    
   g_min_bars_needed_for_ea = MathMax(InpPivotLookbackBars, InpADXPeriod + 5); 
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, InpHAPeriod + InpOscillatorPeriod + 10); 
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, 200);
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, MathMax(26, 100) + 20); // M5: MACD slow=26, EMA slow=100
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, MathMax(26, 200) + 20); // M15: MACD slow=26, EMA slow=200
   g_min_bars_needed_for_ea = MathMax(g_min_bars_needed_for_ea, MathMax(26, 200) + 20); // H1: MACD slow=26, EMA slow=200


   if(InpStartingBalanceOverride > 0.0) g_initial_challenge_balance_prop = InpStartingBalanceOverride;
   else g_initial_challenge_balance_prop = AccountInfoDouble(ACCOUNT_BALANCE);
   
   // Initialize daily and peak tracking with proper initial balance
   g_prop_balance_at_day_start = g_initial_challenge_balance_prop; // Use initial balance, not current
   g_prop_equity_at_day_start = g_initial_challenge_balance_prop;  // Use initial balance, not current
   g_prop_highest_equity_peak = g_initial_challenge_balance_prop;  // Start peak from initial balance
   g_prop_current_trading_days = 0;
   MqlDateTime temp_dt; TimeToStruct(TimeCurrent(),temp_dt); temp_dt.hour=0; temp_dt.min=0; temp_dt.sec=0;
   g_last_day_for_daily_reset = StructToTime(temp_dt); 
   ArrayFree(g_unique_trading_day_dates); 
   
   // Initialize dashboard variables
   g_challenge_cost = InpChallengeCostDollars;
   
   // Initialize slave status variables
   g_slave_balance = 0.0;
   g_slave_equity = 0.0;
   g_slave_daily_pnl = 0.0;
   g_slave_account_number = 0;
   g_slave_account_currency = "";
   g_slave_status_text = "Slave Init...";
   g_slave_is_connected = false;
   g_slave_last_update_in_file = 0;
   g_slave_last_update_processed_time = 0;

   UpdateEAOpenPositionsState(); // Initial check of open positions
   
   // Restore scale-out tracking for any existing positions (when EA is attached to chart with open trades)
   RestoreScaleOutTrackingForExistingPositions();

   string program_name_str = MQLInfoString(MQL_PROGRAM_NAME);
   string init_msg_part1 = program_name_str + " (Master) Initialized. EA Version: " + g_ea_version_str + ", Build: " + IntegerToString(__MQL5BUILD__);
   string init_msg_part2 = ". Initial Prop Balance for Dash: " + DoubleToString(g_initial_challenge_balance_prop, 2);
   Print(init_msg_part1 + init_msg_part2); // Consolidated print statement

   // ENHANCED TARGET CALCULATION LOGGING
   double calculated_target = g_initial_challenge_balance_prop + InpTargetProfitDollars;
   PrintFormat("🎯 TARGET CALCULATION: Initial Balance: %.2f + Target Profit: %.2f = Target Equity: %.2f", 
              g_initial_challenge_balance_prop, InpTargetProfitDollars, calculated_target);
   PrintFormat("📊 TARGET SETTINGS: InpStartingBalanceOverride=%.2f, InpTargetProfitDollars=%.2f, Current Account Balance=%.2f", 
              InpStartingBalanceOverride, InpTargetProfitDollars, AccountInfoDouble(ACCOUNT_BALANCE));
   
   // ENHANCED DD INITIALIZATION LOGGING
   double daily_dd_floor = g_prop_balance_at_day_start - InpDailyDrawdownDollars;
   double daily_dd_90_threshold = g_prop_balance_at_day_start - (InpDailyDrawdownDollars * 0.9);
   double max_dd_floor = g_prop_highest_equity_peak - InpMaxDrawdownDollars;
   double max_dd_90_threshold = g_prop_highest_equity_peak - (InpMaxDrawdownDollars * 0.9);
   
   PrintFormat("⚠️  DAILY DD SETUP: Start Balance: %.2f, DD Limit: %.2f, 90%% Alert: %.2f, Floor: %.2f", 
              g_prop_balance_at_day_start, InpDailyDrawdownDollars, daily_dd_90_threshold, daily_dd_floor);
   PrintFormat("⚠️  MAX DD SETUP: Equity Peak: %.2f, DD Limit: %.2f, 90%% Alert: %.2f, Floor: %.2f", 
              g_prop_highest_equity_peak, InpMaxDrawdownDollars, max_dd_90_threshold, max_dd_floor);
   
   if(InpStartingBalanceOverride > 0.0)
   {
       PrintFormat("⚠️  OVERRIDE ACTIVE: Using override balance %.2f instead of current account balance %.2f", 
                  InpStartingBalanceOverride, AccountInfoDouble(ACCOUNT_BALANCE));
   }
   else
   {
       Print("✅ AUTO-DETECT: Using current account balance as initial balance");
   }
   
   prev_HA_Bias_Oscillator_Value = 0; 
   biasChangedToBullish_MQL = false;
   biasChangedToBearish_MQL = false;
   
   // Initialize EA2 safety verification system (CRITICAL SAFETY)
   InitializeEA2Verification();
   
   // Initialize drawdown tracking
   InitializeDrawdownTracking();
   
   Dashboard_Init();

   double daily_dd_limit_pct = 0.0, max_acc_dd_pct = 0.0, stage_target_pct = 0.0;
   if (g_initial_challenge_balance_prop > 0) 
     {
      daily_dd_limit_pct = (InpDailyDrawdownDollars / g_initial_challenge_balance_prop) * 100.0;
      max_acc_dd_pct     = (InpMaxDrawdownDollars / g_initial_challenge_balance_prop) * 100.0;
      stage_target_pct   = (InpTargetProfitDollars / g_initial_challenge_balance_prop) * 100.0;
     }

   Dashboard_UpdateStaticInfo(
      g_ea_version_str,              
      InpMagicNumber,                 
      g_initial_challenge_balance_prop, 
      daily_dd_limit_pct,             
      max_acc_dd_pct,                 
      stage_target_pct,               
      InpMinTradingDaysRequired,    
      _Symbol,                        
      EnumToString(_Period),          
      InpChallengeCostDollars                
   );
   
   ChartVisuals_InitPivots(InpShowPivotVisuals, InpPivotUpColor, InpPivotDownColor);
   ChartVisuals_InitMarketBias(InpShowMarketBias, InpBullishColor, InpBearishColor);
   
   Comment("SynPropEA1 Initialized. Waiting for signals...");
   return(INIT_SUCCEEDED);
  }
   
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_adx_main != INVALID_HANDLE) IndicatorRelease(h_adx_main);
   // Persist all-time high for drawdown tracking
   GlobalVariableSet("DD_AllTimeHigh", g_all_time_high);
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
   // New bar detection logic based on the close of the previous bar (index 1)
   datetime current_closed_bar_opentime = iTime(_Symbol, _Period, 1);

   // Check for valid time and if it's different from the last stored closed bar time
   if(current_closed_bar_opentime != g_last_closed_bar_opentime_ea1 && current_closed_bar_opentime > 0) 
     {
      // Before assigning, ensure this isn't the very first tick of the EA loading an old bar if g_last_closed_bar_opentime_ea1 is 0.
      // If g_last_closed_bar_opentime_ea1 is 0, it means this is the first pass or EA restart.
      // We want to process this bar as a new bar event.
      if (g_last_closed_bar_opentime_ea1 != 0) {
        // This is a subsequent new bar
        PrintFormat("New Bar Detected: Prev Closed Bar Open: %s, Curr Closed Bar Open: %s", 
                    TimeToString(g_last_closed_bar_opentime_ea1), TimeToString(current_closed_bar_opentime));
      } else {
        // This is the first new bar event since EA start/reset
        PrintFormat("Initial Bar Detected as New: Curr Closed Bar Open: %s (Prev was 0)", 
                    TimeToString(current_closed_bar_opentime));
      }
      g_last_closed_bar_opentime_ea1 = current_closed_bar_opentime;
      isNewBar = true;
     }
   // END New bar detection logic

   UpdateEAOpenPositionsState(); // Update count and type of EA's open positions for this symbol
   
   // Monitor position changes for SL/TP modifications (check every tick)
   UpdateMonitoredPositions();

   // Check if dashboard objects exist, if not reinitialize
   static datetime last_dashboard_check = 0;
   static bool dashboard_init_in_progress = false; // Add flag to prevent multiple reinits
   if(false) // TEMPORARILY DISABLED: TimeCurrent() - last_dashboard_check > 60 && !dashboard_init_in_progress) // Check every 60 seconds instead of 30
   {
       // Check for multiple key dashboard objects to ensure it's really missing
       bool title_missing = (ObjectFind(ChartID(), "SynProp_Title") < 0);
       bool balance_missing = (ObjectFind(ChartID(), "SynProp_Balance_Label") < 0);
       bool status_missing = (ObjectFind(ChartID(), "SynProp_Status_Label") < 0);
       
       if(title_missing && balance_missing && status_missing) // Only reinit if multiple objects are missing
       {
           Print("Dashboard completely missing - reinitializing dashboard");
           dashboard_init_in_progress = true; // Set flag before starting
           Dashboard_Deinit(); // Clean up any remaining objects
           Dashboard_Init(); // Reinitialize dashboard
           dashboard_init_in_progress = false; // Clear flag after completion
       }
       else if(title_missing || balance_missing || status_missing)
       {
           Print("Some dashboard objects missing but not all - skipping reinit to avoid flicker");
       }
       last_dashboard_check = TimeCurrent();
   }

   MqlDateTime current_time_struct; TimeToStruct(TimeCurrent(), current_time_struct);
   
   // Create day boundary at configurable time (default 00:01:00 for 00:01-23:59 period)
   MqlDateTime day_boundary_struct = current_time_struct;
   day_boundary_struct.hour = InpDailyResetHour;
   day_boundary_struct.min = InpDailyResetMinute;
   day_boundary_struct.sec = 0;
   datetime day_boundary = StructToTime(day_boundary_struct);

   if(day_boundary > g_last_day_for_daily_reset)
     {
      // Store previous values for logging
      double previous_balance = g_prop_balance_at_day_start;
      double previous_equity = g_prop_equity_at_day_start;
      
      // Use consistent logic - if override is set, use it for daily reset too
      if(InpStartingBalanceOverride > 0.0)
        {
         g_prop_balance_at_day_start = InpStartingBalanceOverride; // Use override consistently
         g_prop_equity_at_day_start = InpStartingBalanceOverride;  // Use override consistently
         if(InpEnableDailyTrackingLogs)
         {
             PrintFormat("🕐 MASTER DAILY RESET at %s - Override Mode: %.2f (Prev Balance: %.2f, Prev Equity: %.2f)", 
                        TimeToString(day_boundary, TIME_DATE|TIME_MINUTES), InpStartingBalanceOverride,
                        previous_balance, previous_equity);
         }
        }
      else
        {
         g_prop_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE); // Auto-detect daily balance
         g_prop_equity_at_day_start = AccountInfoDouble(ACCOUNT_EQUITY);   // Auto-detect daily equity
         if(InpEnableDailyTrackingLogs)
         {
             PrintFormat("🕐 MASTER DAILY RESET at %s - Auto Mode: Balance=%.2f, Equity=%.2f (Prev: %.2f/%.2f)", 
                        TimeToString(day_boundary, TIME_DATE|TIME_MINUTES), 
                        g_prop_balance_at_day_start, g_prop_equity_at_day_start,
                        previous_balance, previous_equity);
         }
        }
      g_last_day_for_daily_reset = day_boundary;
      
      // Reset daily alerts on new trading day
      ResetDailyAlerts();
     }
   g_prop_highest_equity_peak = MathMax(g_prop_highest_equity_peak, AccountInfoDouble(ACCOUNT_EQUITY));
   
   // --- Live Trade Management Checks (Every Tick) ---
   // Check for target achievement first - if achieved, shut down EA immediately
   if(CheckTargetAchievementShutdown())
   {
       // EA has been shut down due to target achievement - stop all processing
       Comment("🎯 TARGET ACHIEVED - EA SHUTDOWN");
       return;
   }
   
   // Check for 90% DD alerts
   CheckDrawdownAlerts();
   
   string current_status_msg = "Monitoring..."; 
   int signal = 0; 
   is_session_active = IsInTradingSession(); 

   // --- Daily Drawdown Check for Master EA ---   
   bool daily_dd_breached = false;
   double daily_dd_floor = g_prop_balance_at_day_start - InpDailyDrawdownDollars;
   if(AccountInfoDouble(ACCOUNT_EQUITY) <= daily_dd_floor)
     {
      daily_dd_breached = true;
      current_status_msg = StringFormat("Daily DD Limit Hit! Equity %.2f <= Floor %.2f. No new trades.", 
                                       AccountInfoDouble(ACCOUNT_EQUITY), daily_dd_floor);
      Print(current_status_msg);
      // No new signals will be processed if breached. 
      // Existing trades are managed by SL/TP or manual intervention.
     }

   // --- Process Slave Status File ---
   ProcessSlaveStatusFile();
   // --- End Process Slave Status File ---
   
   // --- EA2 Safety Status Logging ---
   LogEA2SafetyStatus();
   // --- End EA2 Safety Status Logging ---

   if(Bars(_Symbol, _Period) < g_min_bars_needed_for_ea && MQLInfoInteger(MQL_TESTER)==false) 
     {
      current_status_msg = StringFormat("Waiting for bars (%d/%d)", (int)Bars(_Symbol, _Period), g_min_bars_needed_for_ea);
     }
   else if(isNewBar) 
     {
      datetime currentCalcBarTime = iTime(_Symbol, _Period, 1); 
      double refPriceForPivots = iClose(_Symbol, _Period, 1); 
      PrintFormat("--- New Bar Calculation for Bar Closed at: %s ---", TimeToString(currentCalcBarTime, TIME_DATE | TIME_MINUTES | TIME_SECONDS));
 
      if(InpUseMarketBias)
        {
         double current_HA_Bias_Oscillator = CalculateHeikinAshiBiasOscillator();
         bool prevBiasPositiveState = prev_HA_Bias_Oscillator_Value > 0.0;
         bool currentBiasPositiveState = current_HA_Bias_Oscillator > 0.0;
         biasChangedToBullish_MQL = !prevBiasPositiveState && currentBiasPositiveState;
         biasChangedToBearish_MQL = prevBiasPositiveState && !currentBiasPositiveState;
         val_HA_Bias_Oscillator = current_HA_Bias_Oscillator; 
         PrintFormat("HA Bias Osc (TF: %s, Value: %.5f). Prev Value: %.5f. ChangedToBull: %s, ChangedToBear: %s",
                     EnumToString(InpMarketBiasTimeframe), val_HA_Bias_Oscillator, prev_HA_Bias_Oscillator_Value, 
                     biasChangedToBullish_MQL ? "Yes" : "No", biasChangedToBearish_MQL ? "Yes" : "No");
         prev_HA_Bias_Oscillator_Value = val_HA_Bias_Oscillator;
        }
      else 
        { val_HA_Bias_Oscillator = 0.0; biasChangedToBullish_MQL = false; biasChangedToBearish_MQL = false; }
 
      // --- Calculate Standard ADX ---
      double adx_main_buf[1], adx_plus_buf[1], adx_minus_buf[1];
      if(Bars(_Symbol, _Period) > InpADXPeriod + 1) 
        {
         val_ADX_Main = (CopyBuffer(h_adx_main, 0, 1, 1, adx_main_buf) > 0) ? adx_main_buf[0] : -1.0;   // Previous bar for confirmed values
         val_ADX_Plus = (CopyBuffer(h_adx_main, 1, 1, 1, adx_plus_buf) > 0) ? adx_plus_buf[0] : -1.0;   // Previous bar for confirmed values  
         val_ADX_Minus = (CopyBuffer(h_adx_main, 2, 1, 1, adx_minus_buf) > 0) ? adx_minus_buf[0] : -1.0; // Previous bar for confirmed values
         PrintFormat("Standard ADX (Main:%.2f, +DI:%.2f, -DI:%.2f) - Threshold: %.2f", val_ADX_Main, val_ADX_Plus, val_ADX_Minus, InpADXThreshold);
        }
      else
        { val_ADX_Main = -1.0; val_ADX_Plus = -1.0; val_ADX_Minus = -1.0; }
 
      if(InpUseSynergyScore)   // Synergy score enabled
        {
         // Use simplified parameters matching Pine Script exactly
         if(InpUseTF5min)
         {
            val_SynergyScore_M5 = CalculateSynergyScore(PERIOD_M5, 14, InpRSIWeight, 10, 100, InpTrendWeight, 12, 26, InpMACDVSlopeWeight, InpWeight_M5, 1);
         }
         else 
         {
            val_SynergyScore_M5 = 0.0;
         }
         
         if(InpUseTF15min)
         {
            val_SynergyScore_M15 = CalculateSynergyScore(PERIOD_M15, 14, InpRSIWeight, 50, 200, InpTrendWeight, 12, 26, InpMACDVSlopeWeight, InpWeight_M15, 1);
         }
         else 
         {
            val_SynergyScore_M15 = 0.0;
         }
         
         if(InpUseTF1hour)
         {
            val_SynergyScore_H1 = CalculateSynergyScore(PERIOD_H1, 14, InpRSIWeight, 50, 200, InpTrendWeight, 12, 26, InpMACDVSlopeWeight, InpWeight_H1, 1);
         }
         else 
         {
            val_SynergyScore_H1 = 0.0;
         }
         
         val_TotalSynergyScore = val_SynergyScore_M5 + val_SynergyScore_M15 + val_SynergyScore_H1;
         PrintFormat("Synergy (M5:%.2f, M15:%.2f, H1:%.2f, Total:%.2f) on current bar", val_SynergyScore_M5, val_SynergyScore_M15, val_SynergyScore_H1, val_TotalSynergyScore);  // Updated log message
        }
      else { val_TotalSynergyScore = 0.0; }
 
      CalculatePivots(recent_pivot_high, recent_pivot_low, refPriceForPivots); 
      PrintFormat("Pivots (ref price %.5f for SL/TP): High: %s at %.5f, Low: %s at %.5f", refPriceForPivots, TimeToString(recent_pivot_high.time, TIME_MINUTES), recent_pivot_high.price, TimeToString(recent_pivot_low.time, TIME_MINUTES), recent_pivot_low.price);
      IdentifyPivotsForVisuals(); 
      Print("Is Trading Session Active: ", is_session_active ? "Yes" : "No");
      
      // Make position status more user-friendly
      string position_status;
      if(g_ea_open_positions_count == 0)
        {
         position_status = "No Positions";
        }
      else
        {
         string direction = (g_ea_open_positions_type == ORDER_TYPE_BUY) ? "LONG" : 
                           (g_ea_open_positions_type == ORDER_TYPE_SELL) ? "SHORT" : "Unknown";
         position_status = StringFormat("%d %s Position%s", g_ea_open_positions_count, direction, 
                                       (g_ea_open_positions_count > 1) ? "s" : "");
        }
      PrintFormat("EA Positions: %s", position_status);
      
      // --- Trade Decision Logic ---
      bool allow_new_trade = false;
      signal = GetTradingSignal(); // Get the potential signal first

      // Check slave connection status BEFORE allowing any new trade consideration
      if (!g_slave_is_connected)
        {
         Print("Master EA: Slave EA is not connected or status is stale. New trades are disabled.");
         current_status_msg = "Slave Disconnected - New Trades Off";
         // Allow_new_trade remains false, existing trades will continue to be managed by their SL/TP by broker or EA logic not dependent on new signals.
        }
      else if (daily_dd_breached) // Check if daily DD was breached on Master account
        {
          // Message is already set, allow_new_trade remains false
          Print("Master EA: Daily DD limit breached. New trades disabled.");
        }
      else if(g_ea_open_positions_count == 0) { // Slave is connected, DD not breached, check for open positions
          allow_new_trade = true; // No open trades, can open new one if signal exists
      } else { // Existing EA trade(s) open & Slave is connected & DD not breached
          if (g_ea_open_positions_count < InpMaxSimultaneousOrders) {
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
              PrintFormat("Pyramiding Check: Max orders (%d) already open. No further pyramiding.", InpMaxSimultaneousOrders);
          }
      }
      
      if(is_session_active && InpAllowNewTrades && allow_new_trade && signal != 0 && g_slave_is_connected && !daily_dd_breached && !g_target_achieved_shutdown) // Added target shutdown check
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
          else if (!InpAllowNewTrades) { current_status_msg = "Trading Disabled"; }
          else if (daily_dd_breached) { /* status already set */ }
          else if (g_target_achieved_shutdown) { current_status_msg = "TARGET ACHIEVED - EA SHUTDOWN"; }
          else if (!g_slave_is_connected && signal !=0) {current_status_msg = "Slave N/A - New Trades Off";} // Specific message if slave is the issue
          else if (signal == 0 && g_ea_open_positions_count == 0) { current_status_msg = "In Session - No Signal"; }
          else if (g_ea_open_positions_count >= InpMaxSimultaneousOrders) { current_status_msg = "Max Orders Open"; }
          else if (g_ea_open_positions_count > 0) { current_status_msg = StringFormat("Position Open (%s)", EnumToString(g_ea_open_positions_type));}
          else { current_status_msg = "No Trade Condition"; } // Generic if other conditions fail
          if (signal !=0 ) Print("Trade conditions not fully met (AllowTrades, Session, Pyramiding rules). No new trade initiated.");
        }
        
      ChartVisuals_UpdatePivots(g_identified_pivots_high, g_identified_pivots_low, InpShowPivotVisuals, InpPivotUpColor, InpPivotDownColor); 
      ChartVisuals_UpdateMarketBias(val_HA_Bias_Oscillator, InpShowMarketBias); 
      
      // --- Scale-Out and Position Management (added to match Pine Script) ---
      ManageScaleOutAndBreakeven();
      
      // Update dashboard status based on whether we are actively looking for a trade signal
      bool can_look_for_trade = is_session_active && InpAllowNewTrades && 
                                ((g_ea_open_positions_count < InpMaxSimultaneousOrders || 
                                (g_ea_open_positions_count > 0 && signal !=0 && 
                                 ((signal == 1 && g_ea_open_positions_type == ORDER_TYPE_BUY) || (signal == -1 && g_ea_open_positions_type == ORDER_TYPE_SELL)))
                                ) && !daily_dd_breached && !g_target_achieved_shutdown) ; // Added target shutdown check
      Dashboard_UpdateStatus(current_status_msg, (signal != 0 && can_look_for_trade) ); 
     } 
    else if (Bars(_Symbol, _Period) >= g_min_bars_needed_for_ea && !isNewBar) 
     {
        // Update status message on non-new-bar ticks
        if (!is_session_active) { current_status_msg = "Session Inactive"; }
        else if (!InpAllowNewTrades) { current_status_msg = "Trading Disabled"; }
        else if (daily_dd_breached) { 
            current_status_msg = StringFormat("Daily DD Limit Hit! Equity %.2f <= Floor %.2f. No new trades.", 
                                          AccountInfoDouble(ACCOUNT_EQUITY), daily_dd_floor);
        }
        else if (g_target_achieved_shutdown) { current_status_msg = "TARGET ACHIEVED - EA SHUTDOWN"; }
        else if (g_ea_open_positions_count >= InpMaxSimultaneousOrders) { current_status_msg = "Max Orders Open"; }
        else if (g_ea_open_positions_count > 0) { current_status_msg = StringFormat("Position Open (%s)", EnumToString(g_ea_open_positions_type));}
        else { current_status_msg = "Monitoring...";  }
        Dashboard_UpdateStatus(current_status_msg, false); // Not actively signaling on non-new-bar
     }

   Dashboard_UpdateDynamicInfo(
      AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoDouble(ACCOUNT_EQUITY),
      g_prop_equity_at_day_start, g_prop_highest_equity_peak, g_prop_current_trading_days,    // FIXED: Use equity at day start
      is_session_active,
      // Add master EA's volume
      g_ea_open_positions_count > 0 ? PositionGetDouble(POSITION_VOLUME) : 0.0,
      daily_dd_floor, // Pass the calculated daily DD floor for display
      InpDailyDrawdownDollars, // Pass the limit itself
      g_initial_challenge_balance_prop - InpMaxDrawdownDollars, // Static Max DD Floor
      g_prop_highest_equity_peak - InpMaxDrawdownDollars, // Trailing Max DD Floor from Peak
      InpMaxDrawdownDollars // Pass the Max DD limit itself
   );
   
   // FIXED: Build comprehensive slave status string for dashboard display
   string comprehensive_slave_status = "";
   if(g_slave_is_connected && g_slave_account_number > 0)
   {
       comprehensive_slave_status = StringFormat("Vol=%.2f,AccNum=%d,Curr=%s,Lev=%d,Srv=%s,Status=%s", 
                                                g_slave_open_volume, g_slave_account_number, g_slave_account_currency,
                                                g_slave_leverage, g_slave_server, g_slave_status_text);
   }
   else
   {
       comprehensive_slave_status = g_slave_status_text; // Keep original status text if no connection
   }
   
   // Update dashboard with comprehensive slave data
   Dashboard_UpdateSlaveStatus(comprehensive_slave_status, g_slave_balance, g_slave_equity, g_slave_daily_pnl, g_slave_is_connected, g_hedge_pnl, g_hedge_loss_percentage, InpChallengeCostDollars);

   // --- UPDATE COST RECOVERY SECTION (CRITICAL - WAS MISSING) ---
   Dashboard_UpdateCostRecovery(g_prop_balance_at_day_start, 
                               AccountInfoDouble(ACCOUNT_EQUITY),
                               g_prop_highest_equity_peak,
                               InpDailyDrawdownDollars,
                               InpMaxDrawdownDollars,
                               g_slave_equity,
                               g_slave_balance,
                               InpChallengeCostDollars);

   // --- UPDATE DAILY PNL BREAKDOWN SECTION ---
   DailyPnLBreakdown prop_daily_pnl = CalculateDailyPnL();
   DailyPnLBreakdown real_daily_pnl;
   real_daily_pnl.total_daily_pnl = g_slave_daily_pnl;
   real_daily_pnl.realized_daily_pnl = CalculateDailyRealizedPnL(false); // false = slave/real account
   real_daily_pnl.unrealized_daily_pnl = real_daily_pnl.total_daily_pnl - real_daily_pnl.realized_daily_pnl;
   
   Dashboard_UpdateDailyPnL(prop_daily_pnl.total_daily_pnl,
                            prop_daily_pnl.realized_daily_pnl,
                            prop_daily_pnl.unrealized_daily_pnl,
                            real_daily_pnl.total_daily_pnl,
                            real_daily_pnl.realized_daily_pnl,
                            real_daily_pnl.unrealized_daily_pnl);

   // --- UPDATE CUMULATIVE PNL TRACKING SECTION ---
   ComprehensiveCumulativePnL prop_cumulative = CalculateComprehensiveCumulativePnL(true); // true = master/prop account
   ComprehensiveCumulativePnL real_cumulative = CalculateComprehensiveCumulativePnL(false); // false = slave/real account
   
   Dashboard_UpdateCumulativePnL(prop_cumulative.total_cumulative_pnl,
                                 prop_cumulative.max_drawdown_percentage,
                                 prop_cumulative.annualized_return_percentage,
                                 real_cumulative.total_cumulative_pnl,
                                 real_cumulative.max_drawdown_percentage,
                                 real_cumulative.annualized_return_percentage,
                                 prop_cumulative.trading_days_elapsed);

   // --- UPDATE DRAWDOWN DASHBOARD ---
   UpdateDrawdownMetrics(InpShowDrawdownDashboard, InpDailyDDLimitPct, InpMaxDDLimitPct);

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

   //+------------------------------------------------------------------+
   //| Write Master Status File for EA2 to Read                        |
   //+------------------------------------------------------------------+
   WriteMasterStatusFile();
  }

//+------------------------------------------------------------------+
// Definitions for CalculateSMAOnArray, CalculateHeikinAshiBiasOscillator, 
// CalculateSynergyScore, CalculatePivots, GetTradingSignal (Standard ADX implementation)
// (These should be present from your existing complete EA file)
//+------------------------------------------------------------------+
bool CalculateEMAOnArray(const double &source_array[], int source_total, int period, double &result_array[])
  {
   if(period <= 0 || source_total < period)
     {
      PrintFormat("CalculateEMAOnArray: Invalid parameters. Period: %d, Source Total: %d. Cannot calculate EMA.", period, source_total);
      return false;
     }
   int result_size = source_total;
   if(ArrayResize(result_array, result_size) < 0)
     {
      Print("CalculateEMAOnArray: Failed to resize result array.");
      return false;
     }
   
   double alpha = 2.0 / (period + 1);
   
   // Initialize first value as SMA of first 'period' values
   double sum = 0;
   for(int j = 0; j < period; j++)
     {
      sum += source_array[j];
     }
   result_array[period - 1] = sum / period;
   
   // Calculate EMA for remaining values
   for(int i = period; i < source_total; i++)
     {
      result_array[i] = alpha * source_array[i] + (1 - alpha) * result_array[i - 1];
     }
   
   return true;
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
   ENUM_TIMEFRAMES ha_tf = InpMarketBiasTimeframe;
   int ha_len = InpHAPeriod;  // Now 100 (was ma_period)
   int osc_len = InpOscillatorPeriod;  // Now 7 (was signal_period)

   // Need enough bars for double EMA smoothing + HA calculation
   int bars_needed = ha_len * 2 + osc_len + 10;
   
   if(Bars(_Symbol, ha_tf) < bars_needed)
     {
      PrintFormat("CalculateHeikinAshiBiasOscillator: Not enough bars on %s (%d) to calculate. Need %d.",
                  EnumToString(ha_tf), (int)Bars(_Symbol, ha_tf), bars_needed);
      return 0.0;
     }

   // Step 1: Get raw OHLC data
   double raw_open[], raw_high[], raw_low[], raw_close[];
   if(ArrayResize(raw_open, bars_needed) < 0 || ArrayResize(raw_high, bars_needed) < 0 ||
      ArrayResize(raw_low, bars_needed) < 0 || ArrayResize(raw_close, bars_needed) < 0)
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to resize raw OHLC arrays.");
      return 0.0;
     }

   // Fill raw OHLC arrays (newest to oldest for time series indexing)
   for(int i = 0; i < bars_needed; i++)
     {
      raw_open[i] = iOpen(_Symbol, ha_tf, bars_needed - 1 - i);
      raw_high[i] = iHigh(_Symbol, ha_tf, bars_needed - 1 - i);
      raw_low[i] = iLow(_Symbol, ha_tf, bars_needed - 1 - i);
      raw_close[i] = iClose(_Symbol, ha_tf, bars_needed - 1 - i);
      
      if(raw_open[i] == 0 && raw_close[i] == 0)
        {
         PrintFormat("CalculateHeikinAshiBiasOscillator: Invalid OHLC data at bar %d", i);
            return 0.0; 
           }
     }

   // Step 2: EMA-smooth raw OHLC (like Pine: o = ta.ema(open, ha_len))
   double ema_open[], ema_high[], ema_low[], ema_close[];
   if(!CalculateEMAOnArray(raw_open, bars_needed, ha_len, ema_open) ||
      !CalculateEMAOnArray(raw_high, bars_needed, ha_len, ema_high) ||
      !CalculateEMAOnArray(raw_low, bars_needed, ha_len, ema_low) ||
      !CalculateEMAOnArray(raw_close, bars_needed, ha_len, ema_close))
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to calculate initial EMA smoothing.");
      return 0.0;
     }

   // Step 3: Calculate Heikin-Ashi values from smoothed OHLC
   int ha_start_idx = ha_len - 1;  // First valid EMA index
   int ha_count = bars_needed - ha_start_idx;
   double ha_close[], ha_open[];
   if(ArrayResize(ha_close, ha_count) < 0 || ArrayResize(ha_open, ha_count) < 0)
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to resize HA arrays.");
      return 0.0;
     }

   // Calculate HA values using smoothed OHLC
   for(int i = 0; i < ha_count; i++)
     {
      int src_idx = ha_start_idx + i;
      
      // HA Close = (O + H + L + C) / 4
      ha_close[i] = (ema_open[src_idx] + ema_high[src_idx] + ema_low[src_idx] + ema_close[src_idx]) / 4.0;
      
      // HA Open calculation
      if(i == 0)
        {
         ha_open[i] = (ema_open[src_idx] + ema_close[src_idx]) / 2.0;
        }
      else
        {
         ha_open[i] = (ha_open[i-1] + ha_close[i-1]) / 2.0;
        }
     }

   // Step 4: EMA-smooth the HA values (like Pine: o2 = ta.ema(haopen, ha_len))
   double ha_open_smooth[], ha_close_smooth[];
   if(!CalculateEMAOnArray(ha_open, ha_count, ha_len, ha_open_smooth) ||
      !CalculateEMAOnArray(ha_close, ha_count, ha_len, ha_close_smooth))
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to calculate HA EMA smoothing.");
      return 0.0;
     }

   // Step 5: Calculate oscillator (like Pine: osc_bias = 100 * (c2 - o2))
   int osc_start_idx = ha_len - 1;  // First valid EMA index
   int osc_count = ha_count - osc_start_idx;
   double raw_osc[];
   if(ArrayResize(raw_osc, osc_count) < 0)
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to resize oscillator array.");
      return 0.0;
     }

   for(int i = 0; i < osc_count; i++)
     {
      int src_idx = osc_start_idx + i;
      raw_osc[i] = 100.0 * (ha_close_smooth[src_idx] - ha_open_smooth[src_idx]);  // ★ 100x multiplier
     }

   // Step 6: EMA-smooth the oscillator (like Pine: osc_smooth = ta.ema(osc_bias, osc_len))
   double final_osc[];
   if(!CalculateEMAOnArray(raw_osc, osc_count, osc_len, final_osc))
     {
      Print("CalculateHeikinAshiBiasOscillator: Failed to calculate final oscillator EMA.");
      return 0.0;
     }

   // Return the most recent value (current bar equivalent)
   int final_size = ArraySize(final_osc);
   if(final_size >= osc_len)
     {
      return final_osc[final_size - 1];  // Most recent smoothed oscillator value
     }
   else
     {
      Print("CalculateHeikinAshiBiasOscillator: Final oscillator array too small.");
      return 0.0;
     }
  }

// CalculateADXThreshold function removed - using standard ADX with simple threshold

//+------------------------------------------------------------------+
double CalculateSynergyScore(ENUM_TIMEFRAMES tf, 
                             int rsi_period, double rsi_w,
                             int ema_fast_period, int ema_slow_period, double trend_w,
                             int macd_fast_period, int macd_slow_period, double macdv_w,
                             double timeframe_w,  // ADDED: Timeframe weight parameter to match Pine Script
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
         if(rsi_val_arr[0] > 50) score += 1.0 * rsi_w * timeframe_w;        // RSI bullish with timeframe weight
         else if(rsi_val_arr[0] < 50) score -= 1.0 * rsi_w * timeframe_w;  // RSI bearish with timeframe weight
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
         if(ema_fast_arr[0] > ema_slow_arr[0]) score += 1.0 * trend_w * timeframe_w;  // EMA bullish trend with timeframe weight
         else if(ema_fast_arr[0] < ema_slow_arr[0]) score -= 1.0 * trend_w * timeframe_w;  // EMA bearish trend with timeframe weight
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
         if(macd_val_curr_arr[0] > macd_val_prev_arr[0]) score += 1.0 * macdv_w * timeframe_w;  // MACD momentum bullish with timeframe weight
         else if(macd_val_curr_arr[0] < macd_val_prev_arr[0]) score -= 1.0 * macdv_w * timeframe_w;  // MACD momentum bearish with timeframe weight
        }
      else PrintFormat("CSynS %s: Failed to copy MACD buffers. CurrOK:%s, PrevOK:%s", EnumToString(tf), curr_ok?"T":"F", prev_ok?"T":"F");
      IndicatorRelease(macd_handle);
     }
   else PrintFormat("CSynS %s: Failed to create iMACD handle. Err: %d", EnumToString(tf), GetLastError());
   
   return score;
  }

//+------------------------------------------------------------------+
// Helper function to detect pivot highs (mimics Pine's ta.pivothigh)
//+------------------------------------------------------------------+
bool IsPivotHigh(int bar_index, int left_bars, int right_bars)
{
    if(bar_index < right_bars || bar_index + left_bars >= Bars(_Symbol, _Period)) 
        return false;
    
    double center_high = iHigh(_Symbol, _Period, bar_index);
    
    // Check left side - all bars must be lower
    for(int i = 1; i <= left_bars; i++)
    {
        if(iHigh(_Symbol, _Period, bar_index + i) >= center_high)
            return false;
    }
    
    // Check right side - all bars must be lower
    for(int i = 1; i <= right_bars; i++)
    {
        if(iHigh(_Symbol, _Period, bar_index - i) >= center_high)
            return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
// Helper function to detect pivot lows (mimics Pine's ta.pivotlow)
//+------------------------------------------------------------------+
bool IsPivotLow(int bar_index, int left_bars, int right_bars)
{
    if(bar_index < right_bars || bar_index + left_bars >= Bars(_Symbol, _Period)) 
        return false;
    
    double center_low = iLow(_Symbol, _Period, bar_index);
    static datetime last_pivot_reject_log_time = 0;
    bool should_log_reject = (TimeCurrent() - last_pivot_reject_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
    
    // Check left side - all bars must be higher
    for(int i = 1; i <= left_bars; i++)
    {
        double left_low = iLow(_Symbol, _Period, bar_index + i);
        if(left_low <= center_low)
        {
            // Debug logging for rejected pivots when center_low is very low (throttled)
            if(center_low < 1.136 && should_log_reject) // Only log for very low values that might be the missing pivot
            {
                PrintFormat("IsPivotLow: Bar %d (%.5f) rejected - left bar +%d has lower/equal low %.5f", 
                           bar_index, center_low, i, left_low);
                last_pivot_reject_log_time = TimeCurrent();
            }
            return false;
        }
    }
    
    // Check right side - all bars must be higher
    for(int i = 1; i <= right_bars; i++)
    {
        double right_low = iLow(_Symbol, _Period, bar_index - i);
        if(right_low <= center_low)
        {
            // Debug logging for rejected pivots when center_low is very low (throttled)
            if(center_low < 1.136 && should_log_reject) // Only log for very low values that might be the missing pivot
            {
                PrintFormat("IsPivotLow: Bar %d (%.5f) rejected - right bar -%d has lower/equal low %.5f", 
                           bar_index, center_low, i, right_low);
                last_pivot_reject_log_time = TimeCurrent();
            }
            return false;
        }
    }
    
    return true;
}

//+------------------------------------------------------------------+
// Find deepest pivot low below current close (matches Pine f_findDeepestPivotLowBelowClose)
//+------------------------------------------------------------------+
bool FindDeepestPivotLowBelowClose(int lookback_bars, double current_close, double &best_price, datetime &best_time)
{
    best_price = 0.0;
    best_time = 0;
    bool found = false;
    
    int bars_available = (int)Bars(_Symbol, _Period);
    int max_lookback = MathMin(lookback_bars, bars_available - InpPivotLeftBars - 1);
    
    bool should_print_debug = (TimeCurrent() - g_last_pivot_debug_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
    
    if(should_print_debug)
    {
        PrintFormat("FindDeepestPivotLowBelowClose: Starting search. Current close: %.5f, Bars available: %d, Max lookback: %d", 
                    current_close, bars_available, max_lookback);
        g_last_pivot_debug_log_time = TimeCurrent();
    }
    
    int pivots_found = 0;
    int bars_checked = 0;
    
    // Scan from most recent pivot-eligible bar backwards (like Pine: for i = 0 to lookback)
    for(int i = 0; i <= max_lookback; i++)
    {
        int bar_index = InpPivotRightBars + i; // Start from first pivot-eligible bar
        
        if(bar_index + InpPivotLeftBars >= bars_available) break;
        
        bars_checked++;
        double bar_low = iLow(_Symbol, _Period, bar_index);
        datetime bar_time = iTime(_Symbol, _Period, bar_index);
        
        // Check if this bar is a pivot low
        if(IsPivotLow(bar_index, InpPivotLeftBars, InpPivotRightBars))
        {
            pivots_found++;
            double pivot_value = bar_low;
            
            // Check if pivot is below current close and deeper than current best
            if(pivot_value < current_close && (!found || pivot_value < best_price))
            {
                best_price = pivot_value;
                best_time = bar_time;
                found = true;
                
                PrintFormat("FindDeepestPivotLowBelowClose: Found deeper pivot at %.5f (distance: %.1f points, bar %d, time %s)",
                           pivot_value, (current_close - pivot_value) / g_point_value, bar_index, TimeToString(bar_time, TIME_MINUTES));
            }
            else if(pivot_value < current_close)
            {
                if(should_print_debug)
                {
                    PrintFormat("FindDeepestPivotLowBelowClose: Found pivot at %.5f (distance: %.1f points, bar %d) but not deeper than current best %.5f",
                               pivot_value, (current_close - pivot_value) / g_point_value, bar_index, best_price);
                }
            }
            else if(pivot_value >= current_close)
            {
                if(should_print_debug)
                {
                    PrintFormat("FindDeepestPivotLowBelowClose: Found pivot at %.5f (bar %d) but above current close %.5f - skipped",
                               pivot_value, bar_index, current_close);
                }
            }
        }
        else
        {
            // For debugging - log some non-pivot bars to see if we're missing any (throttled)
            if(should_print_debug && bar_low < current_close && (!found || bar_low < best_price))
            {
                PrintFormat("FindDeepestPivotLowBelowClose: Bar %d (%.5f, %s) would be deeper but NOT a valid pivot", 
                           bar_index, bar_low, TimeToString(bar_time, TIME_MINUTES));
            }
        }
    }
    
    if(should_print_debug)
    {
        PrintFormat("FindDeepestPivotLowBelowClose: Search complete. Bars checked: %d, Valid pivots found: %d", 
                    bars_checked, pivots_found);
    }
    
    if(found)
    {
        PrintFormat("FindDeepestPivotLowBelowClose: Selected best pivot Low: %.5f (distance: %.1f points from %.5f)",
                   best_price, (current_close - best_price) / g_point_value, current_close);
    }
    else
    {
        if(should_print_debug)
        {
            PrintFormat("FindDeepestPivotLowBelowClose: No pivot low found below %.5f within %d-bar lookback period",
                       current_close, lookback_bars);
        }
    }
    
    return found;
}

//+------------------------------------------------------------------+
// Find highest pivot high above current close (matches Pine f_findHighestPivotHighAboveClose)
//+------------------------------------------------------------------+
bool FindHighestPivotHighAboveClose(int lookback_bars, double current_close, double &best_price, datetime &best_time)
{
    best_price = 0.0;
    best_time = 0;
    bool found = false;
    
    int bars_available = (int)Bars(_Symbol, _Period);
    int max_lookback = MathMin(lookback_bars, bars_available - InpPivotLeftBars - 1);
    
    // Scan from most recent pivot-eligible bar backwards (like Pine: for i = 0 to lookback)
    for(int i = 0; i <= max_lookback; i++)
    {
        int bar_index = InpPivotRightBars + i; // Start from first pivot-eligible bar
        
        if(bar_index + InpPivotLeftBars >= bars_available) break;
        
        if(IsPivotHigh(bar_index, InpPivotLeftBars, InpPivotRightBars))
        {
            double pivot_value = iHigh(_Symbol, _Period, bar_index);
            
            // Check if pivot is above current close and is higher than current best
            if(pivot_value > current_close && (!found || pivot_value > best_price))
            {
                best_price = pivot_value;
                // Apply Pine script offset correction: bar_index - i + pvtLenR  
                int corrected_bar = bar_index; // Already offset-corrected in our indexing
                best_time = iTime(_Symbol, _Period, corrected_bar);
                found = true;
                
                PrintFormat("FindHighestPivotHighAboveClose: Found higher pivot at %.5f (distance: %.1f points, bar %d)",
                           pivot_value, (pivot_value - current_close) / g_point_value, bar_index);
            }
        }
    }
    
    if(found)
    {
        PrintFormat("FindHighestPivotHighAboveClose: Selected best pivot High: %.5f (distance: %.1f points from %.5f)",
                   best_price, (best_price - current_close) / g_point_value, current_close);
    }
    else
    {
        PrintFormat("FindHighestPivotHighAboveClose: No pivot high found above %.5f within %d-bar lookback period",
                   current_close, lookback_bars);
    }
    
    return found;
}

//+------------------------------------------------------------------+
// Main pivot calculation function (rewritten to match Pine script exactly)
//+------------------------------------------------------------------+
void CalculatePivots(PivotPoint &overall_highest_pivot_h, PivotPoint &overall_lowest_pivot_l, double ref_price)
{
    // Initialize outputs
    overall_highest_pivot_h.time = 0;
    overall_highest_pivot_h.price = 0.0; 
    overall_lowest_pivot_l.time = 0;
    overall_lowest_pivot_l.price = 0.0;
    
    // Check minimum bars requirement
    int bars_available = (int)Bars(_Symbol, _Period);
    if(bars_available <= InpPivotLeftBars + InpPivotRightBars + 1) 
    {
        PrintFormat("CalculatePivots: Not enough bars (%d) for pivot calculation. Need at least %d.", 
                   bars_available, InpPivotLeftBars + InpPivotRightBars + 2);
        return;
    }
    
    // Use ref_price as current close (matches Pine script logic)
    double current_close = ref_price;
    
    // Find deepest pivot low below current close (for LONG stop loss)
    double stoploss_long_swing = 0.0;
    datetime stoploss_long_time = 0;
    bool found_low = FindDeepestPivotLowBelowClose(InpPivotLookbackBars, current_close, stoploss_long_swing, stoploss_long_time);
    
    // Find highest pivot high above current close (for LONG take profit)  
    double tp_long_pivot = 0.0;
    datetime tp_long_time = 0;
    bool found_high = FindHighestPivotHighAboveClose(InpPivotLookbackBars, current_close, tp_long_pivot, tp_long_time);
    
    // Set results (matching Pine script assignment logic)
    if(found_low)
    {
        overall_lowest_pivot_l.price = stoploss_long_swing;
        overall_lowest_pivot_l.time = stoploss_long_time;
    }
    
    if(found_high)
    {
        overall_highest_pivot_h.price = tp_long_pivot; 
        overall_highest_pivot_h.time = tp_long_time;
    }
    
    PrintFormat("CalculatePivots: Found Low: %s (%.5f), Found High: %s (%.5f), Ref Price: %.5f", 
               found_low ? "YES" : "NO", overall_lowest_pivot_l.price,
               found_high ? "YES" : "NO", overall_highest_pivot_h.price, 
               ref_price);
}

//+------------------------------------------------------------------+
int GetTradingSignal() 
  {
   bool adx_ok = InpEnableADXFilter ? (val_ADX_Main != -1.0 && val_ADX_Main > InpADXThreshold) : true;
   
   // --- MODIFIED HA BIAS LOGIC ---
   // Original: checks biasChangedToBullish_MQL or biasChangedToBearish_MQL
   // New: checks current state of val_HA_Bias_Oscillator
   // val_HA_Bias_Oscillator > 0  => Bullish, ok for long
   // val_HA_Bias_Oscillator < 0  => Bearish, ok for short
   // val_HA_Bias_Oscillator == 0 => Neutral, not ok for long or short
   bool ha_bias_long_ok = true;
   bool ha_bias_short_ok = true;

   if(InpUseMarketBias)
     {
      // Define a small threshold to consider the bias as neutral, to avoid issues with floating point comparisons to exact zero.
      // You can adjust g_market_bias_neutral_threshold as needed via an input parameter if desired.
      // For now, using a small hardcoded epsilon.
      double neutral_threshold = 0.001; // Example: if val_HA_Bias_Oscillator is between -0.001 and 0.001, it's considered neutral.

      if(val_HA_Bias_Oscillator > neutral_threshold) // Bullish
        {
         ha_bias_long_ok = true;
         ha_bias_short_ok = false; // If bullish, not okay for short
        }
      else if(val_HA_Bias_Oscillator < -neutral_threshold) // Bearish
        {
         ha_bias_long_ok = false; // If bearish, not okay for long
         ha_bias_short_ok = true;
        }
      else // Neutral
        {
         ha_bias_long_ok = false;
         ha_bias_short_ok = false;
        }
     }
   // --- END OF MODIFIED HA BIAS LOGIC ---
   
   bool synergy_long_ok = InpUseSynergyScore ? (val_TotalSynergyScore > 0) : true;   // Synergy score bullish check
   bool synergy_short_ok = InpUseSynergyScore ? (val_TotalSynergyScore < 0) : true;  // Synergy score bearish check

   // Signal debugging (throttled to every 60 seconds)
   static datetime last_signal_debug = 0;
   if(TimeCurrent() - last_signal_debug >= 60)
   {
       PrintFormat("=== SIGNAL DEBUG ===");
            PrintFormat("ADX Filter: %s | ADX: %.2f > Threshold: %.2f = %s",
                InpEnableADXFilter ? "ENABLED" : "DISABLED", val_ADX_Main, InpADXThreshold, adx_ok ? "PASS" : "FAIL");
       PrintFormat("HA Bias Filter: %s | Bullish Change: %s | Bearish Change: %s", 
                   InpUseMarketBias ? "ENABLED" : "DISABLED", 
                   biasChangedToBullish_MQL ? "YES" : "NO", 
                   biasChangedToBearish_MQL ? "YES" : "NO");
       PrintFormat("Synergy Filter: %s | Score: %.2f | Long OK: %s | Short OK: %s", 
                   InpUseSynergyScore ? "ENABLED" : "DISABLED", val_TotalSynergyScore, 
                   synergy_long_ok ? "YES" : "NO", synergy_short_ok ? "YES" : "NO");
       PrintFormat("LONG Signal: ADX(%s) + SynergyLong(%s) + HABiasLong(%s) = %s", 
                   adx_ok ? "✓" : "✗", synergy_long_ok ? "✓" : "✗", ha_bias_long_ok ? "✓" : "✗",
                   (synergy_long_ok && ha_bias_long_ok && adx_ok) ? "LONG SIGNAL" : "NO LONG");
       PrintFormat("SHORT Signal: ADX(%s) + SynergyShort(%s) + HABiasShort(%s) = %s", 
                   adx_ok ? "✓" : "✗", synergy_short_ok ? "✓" : "✗", ha_bias_short_ok ? "✓" : "✗",
                   (synergy_short_ok && ha_bias_short_ok && adx_ok) ? "SHORT SIGNAL" : "NO SHORT");
       PrintFormat("==================");
       last_signal_debug = TimeCurrent();
   }

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
//| Write Command to Slave EA File                                   |
//+------------------------------------------------------------------+
// command_type: "OPEN_LONG", "OPEN_SHORT", "MODIFY_HEDGE", "CLOSE_HEDGE"
void WriteCommandToSlaveFile(string command_type, ulong master_ticket, 
                             string symbol="", double lots=0, double entry_price=0, 
                             double sl_price=0, double tp_price=0) // Made params optional
  {
   WriteCommandToSlaveFile(command_type, master_ticket, symbol, lots, entry_price, sl_price, tp_price, "");
  }

//+------------------------------------------------------------------+
//| Write Command to Slave EA File with Strategy Info                |
//+------------------------------------------------------------------+
void WriteCommandToSlaveFile(string command_type, ulong master_ticket, 
                             string symbol, double lots, double entry_price, 
                             double sl_price, double tp_price, string strategy_info)
  {
   // In Strategy Tester mode, skip file operations but log the command
   if(g_is_tester_mode)
     {
       PrintFormat("Tester Mode - Command '%s' for ticket %d simulated (Symbol: %s, Lots: %.2f, SL: %.5f, TP: %.5f, Strategy: %s)",
                   command_type, master_ticket, symbol, lots, sl_price, tp_price, strategy_info);
      return;
     }
   
   // =====================================================================
   // CRITICAL SAFETY CHECK: EA2 VERIFICATION FOR COMMANDS
   // =====================================================================
   if(!VerifyEA2ReadyForCommand(command_type, master_ticket))
   {
       PrintFormat("🚫 COMMAND BLOCKED: %s for ticket %d - EA2 verification failed", command_type, master_ticket);
       PrintFormat("   📋 Blocked Command Details: Symbol: %s, Lots: %.2f, SL: %.5f, TP: %.5f", 
                  symbol, lots, sl_price, tp_price);
       return; // Block the command from being written
   }

   if(InpCommandFileName == "")
     {
      Print("WriteCommandToSlaveFile: Common command file name is not set. Cannot write command.");
      return;
     }

   // Use effective symbols for file communication
   string effective_master_symbol = GetEffectiveMasterSymbol();
   string expected_slave_symbol = GetExpectedSlaveSymbol();
   string symbol_to_write = (symbol != "") ? symbol : effective_master_symbol;
   
   // Log symbol compatibility if enabled
   if(InpEnableSymbolLogging && (command_type == "OPEN_LONG" || command_type == "OPEN_SHORT"))
   {
       LogSymbolCompatibility("MASTER->SLAVE", effective_master_symbol, expected_slave_symbol);
   }

   int flags = FILE_WRITE|FILE_CSV|FILE_ANSI;
   if(InpUseSharedFolder) flags |= FILE_COMMON;
   g_common_command_file_handle = FileOpen(InpCommandFileName, flags, g_csv_delimiter);

       if(g_common_command_file_handle == INVALID_HANDLE)
         {
      PrintFormat("WriteCommandToSlaveFile: Error opening common command file %s (in shared folder). Error: %d", InpCommandFileName, GetLastError());
      return;
     }

   FileSeek(g_common_command_file_handle, 0, SEEK_END); // Append

       FileWrite(g_common_command_file_handle, command_type);
   // CRITICAL FIX: Write ticket as string to preserve sign and avoid conversion issues
   FileWrite(g_common_command_file_handle, IntegerToString((long)master_ticket)); // Master's ticket is always relevant

       if(command_type == "OPEN_LONG" || command_type == "OPEN_SHORT")
         {
          FileWrite(g_common_command_file_handle, symbol_to_write);
          FileWrite(g_common_command_file_handle, lots);
      FileWrite(g_common_command_file_handle, entry_price); // Master's entry for OPEN
      FileWrite(g_common_command_file_handle, sl_price);    // Master's SL for OPEN
      FileWrite(g_common_command_file_handle, tp_price);    // Master's TP for OPEN
         }
       else if(command_type == "MODIFY_HEDGE")
         {
      FileWrite(g_common_command_file_handle, symbol_to_write); // Symbol might be good for context
      FileWrite(g_common_command_file_handle, 0.0);    // Lots not directly relevant for modify
      FileWrite(g_common_command_file_handle, 0.0);    // Entry price not relevant for modify
      FileWrite(g_common_command_file_handle, sl_price); // This is the new SL for the SLAVE (Master's new TP)
      FileWrite(g_common_command_file_handle, tp_price); // This is the new TP for the SLAVE (Master's new SL)
         }
       else if(command_type == "CLOSE_HEDGE")
         {
      FileWrite(g_common_command_file_handle, symbol_to_write); // Symbol might be good for context
      FileWrite(g_common_command_file_handle, 0.0);    // Lots not relevant
      FileWrite(g_common_command_file_handle, 0.0);    // Entry price not relevant
      FileWrite(g_common_command_file_handle, 0.0);    // SL not relevant
      FileWrite(g_common_command_file_handle, 0.0);    // TP not relevant
         }
       else if(command_type == "SCALEOUT_HEDGE")
         {
      FileWrite(g_common_command_file_handle, symbol_to_write);      // Symbol
      FileWrite(g_common_command_file_handle, lots);        // Volume scaled out by master
      FileWrite(g_common_command_file_handle, entry_price); // Price at which master scaled out
      FileWrite(g_common_command_file_handle, sl_price);    // % of TP distance master scaled out at
      FileWrite(g_common_command_file_handle, tp_price);    // Reserved for future use
         }
       else // Unknown command type
         {
           FileWrite(g_common_command_file_handle, symbol_to_write);
           FileWrite(g_common_command_file_handle, lots);
           FileWrite(g_common_command_file_handle, entry_price);
           FileWrite(g_common_command_file_handle, sl_price);
           FileWrite(g_common_command_file_handle, tp_price);
         }

       // Write strategy info as additional field for SCALEOUT_HEDGE commands
       if(command_type == "SCALEOUT_HEDGE" && strategy_info != "")
         {
          FileWrite(g_common_command_file_handle, strategy_info);
         }

       long current_time_long = TimeCurrent();
   string timestamp_to_write_str = IntegerToString(current_time_long);
   FileWrite(g_common_command_file_handle, timestamp_to_write_str); 
   // PrintFormat("DEBUG EA1: Timestamp string written to file: '%s' (Raw long was: %d)", timestamp_to_write_str, current_time_long);

       FileClose(g_common_command_file_handle);
   PrintFormat("WriteCommandToSlaveFile: Command '%s' written for ticket %d. Symbol: %s, Lots: %.2f, SL: %.5f, TP: %.5f, Strategy: %s",
               command_type, master_ticket, symbol_to_write, lots, sl_price, tp_price, strategy_info); // Adjusted print for brevity
  }

//+------------------------------------------------------------------+
//| Process Slave EA Status File                                     |
//+------------------------------------------------------------------+
void ProcessSlaveStatusFile()
  {
   // In Strategy Tester mode, bypass slave file processing and assume connected
   if(g_is_tester_mode)
   {
       g_slave_is_connected = true;
       g_slave_status_text = "Tester Mode - Slave Simulated";
       g_slave_balance = AccountInfoDouble(ACCOUNT_BALANCE);
       g_slave_equity = AccountInfoDouble(ACCOUNT_EQUITY);
       g_slave_daily_pnl = 0.0;
       g_slave_account_number = AccountInfoInteger(ACCOUNT_LOGIN);
       g_slave_account_currency = AccountInfoString(ACCOUNT_CURRENCY);
       g_slave_last_update_in_file = TimeCurrent();
       g_slave_last_update_processed_time = TimeCurrent();
       g_slave_open_volume = 0.0;
       g_slave_leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
       g_slave_server = AccountInfoString(ACCOUNT_SERVER);
       return;
   }

   if(InpSlaveEAStatusFile == "")
     {
      g_slave_is_connected = false;
      g_slave_status_text = "Slave File N/A";
      bool should_print_slave_debug = (TimeCurrent() - g_last_slave_debug_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
      if(should_print_slave_debug)
      {
          PrintFormat("ProcessSlaveStatusFile: InpSlaveStatusFile is empty - no slave status file configured");
          g_last_slave_debug_log_time = TimeCurrent();
      }
      return;
     }

   // Reset previous status slightly
   g_slave_is_connected = false; 
   // Don't reset text immediately, keep last known if file read fails temporarily

    // Added FILE_COMMON flag
   int flags_slave = FILE_READ | FILE_CSV | FILE_ANSI;
   if(InpUseSharedFolder) 
       flags_slave |= FILE_COMMON;
   g_slave_status_file_handle = FileOpen(InpSlaveEAStatusFile, flags_slave, g_csv_delimiter);
   if(g_slave_status_file_handle == INVALID_HANDLE)
     {
      // Only update status text if it's not already indicating a file error, to avoid spamming logs
      if(g_slave_last_update_processed_time == 0 || TimeCurrent() - g_slave_last_update_processed_time > 60) // e.g. if no update for 1 min
      {
        g_slave_status_text = "Slave File Read Err";
        bool should_print_slave_debug = (TimeCurrent() - g_last_slave_debug_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
        if(should_print_slave_debug)
        {
            PrintFormat("ProcessSlaveStatusFile: Error opening slave status file '%s'. Error: %d", InpSlaveEAStatusFile, GetLastError());
            g_last_slave_debug_log_time = TimeCurrent();
        }
      }
      g_slave_is_connected = false;
      return;
     }

   if(!FileIsEnding(g_slave_status_file_handle))
     {
      // Assuming format: Balance;Equity;DailyPnL;AccountNumber;AccountCurrency;StatusText;IsConnected(true/false);FileTimestamp(long);OpenVolume;Leverage;Server
      string s_balance = FileReadString(g_slave_status_file_handle);
      string s_equity = FileReadString(g_slave_status_file_handle);
      string s_daily_pnl = FileReadString(g_slave_status_file_handle);
      string s_acc_num = FileReadString(g_slave_status_file_handle);
      string s_acc_curr = FileReadString(g_slave_status_file_handle);
      string s_status_text = FileReadString(g_slave_status_file_handle);
      string s_is_connected = FileReadString(g_slave_status_file_handle);
      string s_file_timestamp = FileReadString(g_slave_status_file_handle);
      
      // Read the new fields directly, assuming they are present
      string s_open_volume = FileReadString(g_slave_status_file_handle);
      string s_leverage = FileReadString(g_slave_status_file_handle);
      string s_server = FileReadString(g_slave_status_file_handle); // This should be the last field

      // Check if line/file ended AFTER reading all expected fields for the current record
      bool line_properly_ended = FileIsLineEnding(g_slave_status_file_handle) || FileIsEnding(g_slave_status_file_handle);
      
      if (s_file_timestamp != "" && line_properly_ended) // Basic check that we got up to the timestamp AND the line ended as expected
        {
            g_slave_balance = StringToDouble(s_balance);
            g_slave_equity = StringToDouble(s_equity);
            g_slave_daily_pnl = StringToDouble(s_daily_pnl);
            g_slave_account_number = StringToInteger(s_acc_num);
            g_slave_account_currency = s_acc_curr;
            g_slave_status_text = s_status_text;
            g_slave_last_update_in_file = (datetime)StringToInteger(s_file_timestamp);

            // Process new fields - StringToDouble/Integer handle empty strings by returning 0
            g_slave_open_volume = StringToDouble(s_open_volume);
            g_slave_leverage = (int)StringToInteger(s_leverage);
            g_slave_server = s_server; 

            if (g_slave_server == "") g_slave_server = "N/A"; // Explicit default if server string is empty after read

            // Calculate hedge P&L and percentage loss
            g_hedge_pnl = g_slave_equity - g_slave_balance; // Simplified hedge P&L calculation
            if(g_hedge_pnl < 0.0 && InpChallengeCostDollars > 0.0)
            {
                g_hedge_loss_percentage = (MathAbs(g_hedge_pnl) / InpChallengeCostDollars) * 100.0;
            }
            else
            {
                g_hedge_loss_percentage = 0.0;
            }
            g_last_hedge_data_update = TimeCurrent();

            // PrintFormat("ProcessSlaveStatusFile DEBUG: Parsed Slave Data: Vol=%.2f, Lev=%d, Srv='%s', AccNum=%d, Curr='%s', Bal=%.2f, Eq=%.2f, PNL=%.2f, ConnectedStr=%s, Timestamp=%s (%d)",
            //             g_slave_open_volume, g_slave_leverage, g_slave_server, 
            //             g_slave_account_number, g_slave_account_currency, g_slave_balance, g_slave_equity, g_slave_daily_pnl,
            //             s_is_connected, TimeToString(g_slave_last_update_in_file), g_slave_last_update_in_file );

            // Check freshness of data
            if(TimeCurrent() - g_slave_last_update_in_file > 120) // If data in file is older than 2 minutes
            {
                g_slave_is_connected = false;
                g_slave_status_text = "Slave Data Stale";
                g_slave_open_volume = 0.0;
                g_slave_leverage = 0;
                g_slave_server = "Stale";
            }
            else 
            {
                 g_slave_is_connected = (s_is_connected == "true" || s_is_connected == "1");
                 if (!g_slave_is_connected && g_slave_status_text != "Slave Data Stale") g_slave_status_text = "Slave Not Conn."; 
            }
            g_slave_last_update_processed_time = TimeCurrent(); 
        }
      else // Line was not properly terminated, or essential s_file_timestamp was empty
        {
            if(g_slave_last_update_processed_time == 0 || TimeCurrent() - g_slave_last_update_processed_time > 60)
            {
                g_slave_status_text = "Slave File Format Err";
            if (!line_properly_ended && s_file_timestamp != "") g_slave_status_text = "Slave File Fmt (LineEnd)";
            bool should_print_slave_debug = (TimeCurrent() - g_last_slave_debug_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
            if(should_print_slave_debug)
            {
                PrintFormat("ProcessSlaveStatusFile: Format error. LineProperlyEnded: %s, s_file_timestamp: '%s'", 
                            line_properly_ended?"true":"false", s_file_timestamp);
                g_last_slave_debug_log_time = TimeCurrent();
            }
            }
            g_slave_is_connected = false;
         g_slave_open_volume = 0.0;
         g_slave_leverage = 0;
         g_slave_server = "FmtErr";
        }
     }
   else // File is ending (empty or already read)
     {
      if(g_slave_last_update_processed_time == 0 || TimeCurrent() - g_slave_last_update_processed_time > 60)
      {
        g_slave_status_text = "Slave File Empty";
        // Print("ProcessSlaveStatusFile: Slave status file is empty."); // Already throttled by outer condition
      }
      g_slave_is_connected = false;
     }
   FileClose(g_slave_status_file_handle);
   
   // Update EA2 verification status based on slave status file content
   string status_content = "";
   if(g_slave_is_connected && g_slave_status_text != "" && g_slave_status_text != "Slave File N/A" && 
      g_slave_status_text != "Slave File Read Err" && g_slave_status_text != "Slave File Format Err" && 
      g_slave_status_text != "Slave File Empty" && g_slave_status_text != "Slave Data Stale")
   {
       status_content = StringFormat("%s|Balance:%.2f|Equity:%.2f|Connected:%s|Server:%s|Leverage:%d",
                                   g_slave_status_text, g_slave_balance, g_slave_equity, 
                                   g_slave_is_connected ? "YES" : "NO", g_slave_server, g_slave_leverage);
   }
   UpdateEA2VerificationFromStatus(status_content);
  }

//+------------------------------------------------------------------+
//| Write Master Status File for EA2 to Read                        |
//+------------------------------------------------------------------+
void WriteMasterStatusFile()
{
    // In Strategy Tester mode, skip file operations
    if(g_is_tester_mode)
    {
        return;
    }

    if(InpMasterEAStatusFile == "") return;

    int flags_master = FILE_WRITE | FILE_CSV | FILE_ANSI;
    if(InpUseSharedFolder) 
        flags_master |= FILE_COMMON;
    int file_handle = FileOpen(InpMasterEAStatusFile, flags_master, g_csv_delimiter);
    if(file_handle == INVALID_HANDLE)
    {
        bool should_print_master_debug = (TimeCurrent() - g_last_master_debug_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
        if(should_print_master_debug)
        {
            PrintFormat("WriteMasterStatusFile: Error opening status file '%s' for writing. Error: %d", InpMasterEAStatusFile, GetLastError());
            g_last_master_debug_log_time = TimeCurrent();
        }
        return;
    }
    
    datetime current_timestamp = TimeCurrent();
    
    // Write indicator values in a format EA2 can easily read
    // Format: TotalSynergyScore,SynergyM5,SynergyM15,SynergyH1,ADXMain,ADXPlus,ADXMinus,ADXThreshold,HABiasOscillator,SessionActive,Timestamp
    FileWrite(file_handle, DoubleToString(val_TotalSynergyScore, 2));
    FileWrite(file_handle, DoubleToString(val_SynergyScore_M5, 2));
    FileWrite(file_handle, DoubleToString(val_SynergyScore_M15, 2));
    FileWrite(file_handle, DoubleToString(val_SynergyScore_H1, 2));
             FileWrite(file_handle, DoubleToString(val_ADX_Main, 2));
         FileWrite(file_handle, DoubleToString(val_ADX_Plus, 2));
         FileWrite(file_handle, DoubleToString(val_ADX_Minus, 2));
         FileWrite(file_handle, DoubleToString(InpADXThreshold, 2));
    FileWrite(file_handle, DoubleToString(val_HA_Bias_Oscillator, 4));
    FileWrite(file_handle, is_session_active ? "true" : "false");
    FileWrite(file_handle, IntegerToString(current_timestamp));

    FileClose(file_handle);
  }

//+------------------------------------------------------------------+
//| Trade Event Function                                             |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
   PrintFormat("OnTradeTransaction: Fired. TransType: %s, Order: %d, Position: %d, Deal: %d, RequestAction: %s", 
               EnumToString(trans.type), trans.order, trans.position, trans.deal, EnumToString(request.action));

   // Log details for SL/TP modification requests regardless of transaction type
   if (request.action == TRADE_ACTION_SLTP && request.position != 0)
     {
      PrintFormat("OnTradeTransaction: SL/TP modification request detected! Position: %d, RequestMagic: %d, RequestSL: %.5f, RequestTP: %.5f", 
                  request.position, request.magic, request.sl, request.tp);
     }
   
   // Also check for position modifications when request action is unknown (0) or when position field is set
   if (request.position != 0 && (request.sl != 0 || request.tp != 0))
     {
      PrintFormat("OnTradeTransaction: Position modification detected (RequestAction: %s). Position: %d, RequestSL: %.5f, RequestTP: %.5f", 
                  EnumToString(request.action), request.position, request.sl, request.tp);
      
      // Check if this is our EA's position
      if (PositionSelectByTicket(request.position))
        {
         long position_magic = PositionGetInteger(POSITION_MAGIC);
         string selected_pos_symbol = PositionGetString(POSITION_SYMBOL);
         
         if (position_magic == InpMagicNumber && (selected_pos_symbol == _Symbol || _Symbol == ""))
           {
            PrintFormat("OnTradeTransaction: Confirmed EA position modification #%d. Magic: %d, Symbol: %s. New SL: %.5f, New TP: %.5f. Sending MODIFY_HEDGE.",
                        request.position, position_magic, selected_pos_symbol, request.sl, request.tp);
            
            // Send MODIFY_HEDGE command (slave SL = master TP, slave TP = master SL)
            WriteCommandToSlaveFile("MODIFY_HEDGE", request.position, selected_pos_symbol, 0, 0, request.tp, request.sl);
           }
        }
     }

   if (trans.type != TRADE_TRANSACTION_DEAL_ADD)
     {
      // Don't exit early for SL/TP modifications - we need to process them even if no deal is added
      if (request.action != TRADE_ACTION_SLTP && request.position == 0)
        {
         // Print("OnTradeTransaction: Exiting - Not TRADE_TRANSACTION_DEAL_ADD and not SL/TP modification.");
      return;
     }
        }
      else
        {
      Print("OnTradeTransaction: Is TRADE_TRANSACTION_DEAL_ADD.");
     }

   ulong deal_order_ticket = trans.order;
   long deal_order_magic = 0;
   if (deal_order_ticket != 0)
     {
      deal_order_magic = HistoryOrderGetInteger(deal_order_ticket, ORDER_MAGIC);
     }
   PrintFormat("OnTradeTransaction: Deal Order Ticket: %d, Deal Order Magic: %d (EA Magic: %d)", 
               deal_order_ticket, deal_order_magic, InpMagicNumber);

   ulong affected_position_ticket = trans.position; 
   if(affected_position_ticket == 0)
     {
      Print("OnTradeTransaction: Exiting - Affected Position Ticket is 0.");
      return;
     }
   PrintFormat("OnTradeTransaction: Affected Position Ticket: %d", affected_position_ticket);

   string transaction_symbol = trans.symbol;
   if(transaction_symbol != _Symbol && _Symbol != "") 
     {
      PrintFormat("OnTradeTransaction: Exiting - Symbol mismatch. TransSymbol: %s, EA Symbol: %s", transaction_symbol, _Symbol);
      return;
     }
   PrintFormat("OnTradeTransaction: Symbol OK (TransSymbol: %s, EA Symbol: %s)", transaction_symbol, _Symbol);

   // If a deal has occurred and it relates to a position ticket, 
   // and that position ticket no longer selects (is closed),
   // we will send a CLOSE_HEDGE command for this position ticket.
   // We are currently assuming that if this EA is monitoring transactions, any closed position 
   // it detects on its symbol was likely one it managed, even if the closing order's magic is 0 (e.g. manual close or SL/TP).
   if(!PositionSelectByTicket(affected_position_ticket))
     {
      PrintFormat("OnTradeTransaction: Position #%d (Master) for %s detected as closed. Deal #%d from Order #%d (OrderMagic: %d). Sending CLOSE_HEDGE command.",
                  affected_position_ticket, transaction_symbol, trans.deal, deal_order_ticket, deal_order_magic);
      WriteCommandToSlaveFile("CLOSE_HEDGE", affected_position_ticket, transaction_symbol);
           }
         else
           {
      PrintFormat("OnTradeTransaction: Position #%d still selectable. Current Volume: %.2f. Not considered closed by this check.", 
                  affected_position_ticket, PositionGetDouble(POSITION_VOLUME));
      // Additional check: If it's an opening deal for OUR EA, we don't want to mistake it for a close.
      // The WriteCommandToSlaveFile for OPEN is already in the OpenTrade function.
      // This OnTradeTransaction is primarily for detecting external closures or future modifications.
      if (deal_order_magic == InpMagicNumber && trans.deal != 0) // A deal from our EA's order
        {
          // This could be the opening deal. We don't need to do anything here for opening.
          PrintFormat("OnTradeTransaction: Deal #%d (Order #%d, Magic %d) is from our EA. Position #%d volume: %.2f. This is likely an opening/modifying deal, not a closure for this logic block.",
                       trans.deal, deal_order_ticket, deal_order_magic, affected_position_ticket, PositionGetDouble(POSITION_VOLUME));
        }
     }

   // --- Check for SL/TP modifications based on the request object ---
   // This part specifically targets modifications like dragging SL/TP on the chart.
   if (request.action == TRADE_ACTION_SLTP && request.position != 0)
     {
      ulong position_ticket_for_sltp_mod = request.position; // Position ticket from the request
      if (PositionSelectByTicket(position_ticket_for_sltp_mod)) 
        {
         // Check if this position belongs to our EA by checking magic number and symbol
         long position_magic = PositionGetInteger(POSITION_MAGIC);
         string selected_pos_symbol = PositionGetString(POSITION_SYMBOL);
         
         if (position_magic == InpMagicNumber && (selected_pos_symbol == _Symbol || _Symbol == ""))
           {
            double new_master_sl = request.sl; // SL from the request (this is master's new SL)
            double new_master_tp = request.tp; // TP from the request (this is master's new TP)

            PrintFormat("OnTradeTransaction: Detected SL/TP modification for EA position #%d (%s). Magic: %d. New Master SL: %.5f, New Master TP: %.5f. Sending MODIFY_HEDGE.",
                        position_ticket_for_sltp_mod, selected_pos_symbol, position_magic, new_master_sl, new_master_tp);
            
            // For MODIFY_HEDGE command to slave:
            // slave's SL = master's new TP
            // slave's TP = master's new SL
            WriteCommandToSlaveFile("MODIFY_HEDGE", position_ticket_for_sltp_mod, selected_pos_symbol, 0, 0, new_master_tp, new_master_sl); 
           }
         else
           {
            PrintFormat("OnTradeTransaction: SL/TP modification for position #%d (Magic: %d, Symbol: %s), but not our EA's position (Magic: %d, Symbol: %s). Ignoring.", 
                        position_ticket_for_sltp_mod, position_magic, selected_pos_symbol, InpMagicNumber, _Symbol);
              }
           }
         else
           {
         PrintFormat("OnTradeTransaction: SL/TP modification request for position #%d, but position could not be selected.", position_ticket_for_sltp_mod);
        }
     }
}

//+------------------------------------------------------------------+
// Scale-Out Helper Functions (added to match Pine Script)
//+------------------------------------------------------------------+

// Function to calculate price at percentage of range (matches Pine Script getPriceAtPctOfRange)
double GetPriceAtPctOfRange(double startPrice, double endPrice, double pct)
{
    return startPrice + ((endPrice - startPrice) * pct / 100.0);
}

// Function to reset scale-out flags on new trade (call when opening new positions)
void ResetScaleOutFlags()
{
    g_scaleOut1LongTriggered = false;
    g_scaleOut1ShortTriggered = false;
    g_beAppliedLong = false;
    g_beAppliedShort = false;
}

// Function to partially close position (matches Pine Script scale-out logic)
bool PartialClosePosition(double lotSizeToClose, string comment = "Scale-Out")
{
    if(g_ea_open_positions_count == 0) return false;
    
    // Find the first position with our magic number
    int total_positions = PositionsTotal();
    for(int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
               PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                double current_volume = PositionGetDouble(POSITION_VOLUME);
                double requested_close_volume = lotSizeToClose;
                
                // Enhanced volume validation and debugging
                double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
                double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
                double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
                
                PrintFormat("PartialClosePosition DEBUG: Position #%d, Current Volume: %.2f, Requested Close: %.2f", 
                           ticket, current_volume, requested_close_volume);
                PrintFormat("PartialClosePosition DEBUG: Symbol Constraints - Min: %.2f, Max: %.2f, Step: %.2f", 
                           min_volume, max_volume, volume_step);
                
                // Ensure we don't try to close more than available
                double close_volume = MathMin(requested_close_volume, current_volume);
                
                // Ensure minimum volume requirement
                if(close_volume < min_volume)
                {
                    PrintFormat("PartialClosePosition ERROR: Calculated close volume %.2f < minimum %.2f. Cannot execute partial close.", 
                               close_volume, min_volume);
                    return false;
                }
                
                // Ensure volume step compliance
                if(volume_step > 0)
                {
                    close_volume = MathRound(close_volume / volume_step) * volume_step;
                    close_volume = MathMax(close_volume, min_volume); // Ensure still above minimum after rounding
                    close_volume = MathMin(close_volume, current_volume); // Ensure still within position size
                }
                
                // Final validation
                if(close_volume <= 0 || close_volume > current_volume)
                {
                    PrintFormat("PartialClosePosition ERROR: Invalid final close volume %.2f (Position: %.2f). Aborting.", 
                               close_volume, current_volume);
                    return false;
                }
                
                PrintFormat("PartialClosePosition: Attempting to close %.2f lots from position #%d (%.2f total). Comment: %s", 
                           close_volume, ticket, current_volume, comment);
                
                CTrade trade;
                trade.SetDeviationInPoints(3); // Set slippage tolerance
                bool result = trade.PositionClosePartial(ticket, close_volume);
                
                if(result)
                {
                    PrintFormat("✅ PartialClosePosition: Successfully closed %.2f lots from position #%d. Comment: %s", 
                              close_volume, ticket, comment);
                    
                    // Get current market price for scale-out command
                    ENUM_POSITION_TYPE pos_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                    double current_market_price = (pos_type == POSITION_TYPE_BUY) ? 
                                                 SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                                                 SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                    
                    // Send partial close command to slave EA
                    string hedge_strategy_info = StringFormat("STRATEGY=%d,REDUCTION=%.1f,BE=%s,TRIGGER=%.1f,COST=%.2f", 
                                                              (int)InpHedgeScaleOutStrategy, 
                                                              InpHedgeScaleOutReduction,
                                                              InpHedgeBreakevenOnMasterScaleOut ? "true" : "false",
                                                              InpHedgeInverseTriggerPct,
                                                              InpChallengeCostDollars);
                    WriteCommandToSlaveFile("SCALEOUT_HEDGE", ticket, _Symbol, close_volume, current_market_price, 
                                          InpScaleOut1Pct, 0, hedge_strategy_info);
                    return true;
                }
                else
                {
                    uint error_code = GetLastError();
                    PrintFormat("❌ PartialClosePosition: Failed to partially close position #%d. Error: %d (%s)", 
                              ticket, error_code, trade.ResultRetcodeDescription());
                    PrintFormat("PartialClosePosition: Trade result - Retcode: %d, Deal: %d, Order: %d, Volume: %.2f", 
                               trade.ResultRetcode(), trade.ResultDeal(), trade.ResultOrder(), trade.ResultVolume());
                    return false;
                }
            }
        }
    }
    
    PrintFormat("PartialClosePosition ERROR: No position found with magic %d and symbol %s", InpMagicNumber, _Symbol);
    return false;
}

//+------------------------------------------------------------------+
// Scale-Out and Position Management (added to match Pine Script)
//+------------------------------------------------------------------+
void ManageScaleOutAndBreakeven()
{
    if(g_ea_open_positions_count == 0) return;
    
    // Get current position details
    ulong position_ticket = 0;
    double position_volume = 0;
    double entry_price = 0;
    ENUM_POSITION_TYPE position_type = WRONG_VALUE;
    
    // Find our position
    int total_positions = PositionsTotal();
    for(int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
               PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                position_ticket = ticket;
                position_volume = PositionGetDouble(POSITION_VOLUME);
                entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
                position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                break;
            }
        }
    }
    
    if(position_ticket == 0) return; // No position found
    
    double current_price = (position_type == POSITION_TYPE_BUY) ? 
                          SymbolInfoDouble(_Symbol, SYMBOL_BID) : 
                          SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    
    // ENHANCED DEBUG LOGGING FOR SCALE-OUT ISSUES
    static datetime last_scaleout_debug = 0;
    bool should_debug = (TimeCurrent() - last_scaleout_debug >= 30); // Every 30 seconds when position is open
    
    if(should_debug)
    {
        PrintFormat("=== SCALE-OUT DEBUG === Pos: #%d, Type: %s, Entry: %.5f, Current: %.5f", 
                   position_ticket, position_type == POSITION_TYPE_BUY ? "LONG" : "SHORT", entry_price, current_price);
        PrintFormat("Scale-Out Settings: Enabled=%s, ScaleOut1Enabled=%s, Pct=%.1f%%, Size=%.1f%%, BE=%s", 
                   InpEnableScaleOut ? "YES" : "NO", InpScaleOut1Enabled ? "YES" : "NO", 
                   InpScaleOut1Pct, InpScaleOut1Size, InpScaleOut1BE ? "YES" : "NO");
        last_scaleout_debug = TimeCurrent();
    }
    
    // LONG POSITION MANAGEMENT (matches Pine Script)
    if(position_type == POSITION_TYPE_BUY)
    {
        double pip_to_points_multiplier = GetPipToPointsMultiplier();
        double dist_in_pips = (current_price - entry_price) / (g_point_value * pip_to_points_multiplier);
        
        if(should_debug)
        {
            PrintFormat("LONG DEBUG: LastEntryLots=%.2f, TpEntry=%.5f, Triggered=%s, Dist=%.1f pips", 
                       g_lastEntryLots, g_pivotTpLongEntry, g_scaleOut1LongTriggered ? "YES" : "NO", dist_in_pips);
        }
        
        // Scale-out logic for long positions
        if(InpEnableScaleOut && InpScaleOut1Enabled && !g_scaleOut1LongTriggered && g_pivotTpLongEntry > 0)
        {
            // Calculate scale-out price at specified percentage of the target distance
            double scaleOut1Price = GetPriceAtPctOfRange(entry_price, g_pivotTpLongEntry, InpScaleOut1Pct);
            double tp_distance_points = (g_pivotTpLongEntry - entry_price) / g_point_value;
            double current_progress_pct = ((current_price - entry_price) / (g_pivotTpLongEntry - entry_price)) * 100.0;
            
            if(should_debug)
            {
                PrintFormat("LONG Scale-Out: TP Distance=%.1f points, ScaleOut@%.5f (%.1f%%), Current Progress=%.1f%%", 
                           tp_distance_points, scaleOut1Price, InpScaleOut1Pct, current_progress_pct);
                PrintFormat("LONG Scale-Out Trigger Check: Current %.5f >= Target %.5f ? %s", 
                           current_price, scaleOut1Price, current_price >= scaleOut1Price ? "YES - TRIGGER!" : "NO");
            }
            
            // Execute scale-out when price reaches the level
            if(current_price >= scaleOut1Price)
            {
                g_scaleOut1LongTriggered = true;
                
                // Enhanced volume calculation with debugging
                double scale_out_percentage = InpScaleOut1Size / 100.0;
                double calculated_partial_qty = g_lastEntryLots * scale_out_percentage;
                double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
                double partialQty = MathMax(calculated_partial_qty, min_volume);
                
                // Additional validation: ensure it doesn't exceed current position volume
                partialQty = MathMin(partialQty, position_volume);
                
                PrintFormat("🎯 SCALE-OUT LONG TRIGGERED! Entry: %.5f, Current: %.5f, Target: %.5f (%.1f%% of %.1f points)", 
                           entry_price, current_price, scaleOut1Price, InpScaleOut1Pct, tp_distance_points);
                PrintFormat("📊 VOLUME CALCULATION: g_lastEntryLots=%.2f * %.1f%% = %.2f, Min=%.2f, Position=%.2f, Final=%.2f", 
                           g_lastEntryLots, InpScaleOut1Size, calculated_partial_qty, min_volume, position_volume, partialQty);
                           
                if(PartialClosePosition(partialQty, "Scale-Out"))
                {
                    PrintFormat("✅ Scale-Out LONG executed: %.2f lots at %.5f (%.1f%% of TP distance)", 
                              partialQty, current_price, InpScaleOut1Pct);
                    
                    // Set breakeven if enabled
                    if(InpScaleOut1BE && !g_beAppliedLong)
                    {
                        g_beAppliedLong = true;
                        g_pivotStopLongEntry = entry_price;
                        ModifyPositionStopLoss(position_ticket, entry_price, "BE_After_ScaleOut");
                    }
                }
                else
                {
                    PrintFormat("❌ Scale-Out LONG FAILED to execute partial close!");
                }
            }
        }
        else if(should_debug)
        {
            // Debug why scale-out is not being checked
            if(!InpEnableScaleOut) PrintFormat("LONG Scale-Out DISABLED: InpEnableScaleOut = false");
            if(!InpScaleOut1Enabled) PrintFormat("LONG Scale-Out DISABLED: InpScaleOut1Enabled = false");
            if(g_scaleOut1LongTriggered) PrintFormat("LONG Scale-Out ALREADY TRIGGERED");
            if(g_pivotTpLongEntry <= 0) PrintFormat("LONG Scale-Out DISABLED: No valid TP stored (g_pivotTpLongEntry = %.5f)", g_pivotTpLongEntry);
        }
        
        // Regular breakeven (separate from scale-out)
        if(InpEnableBreakEven && !g_beAppliedLong && dist_in_pips >= InpBETriggerPips)
        {
            g_beAppliedLong = true;
            g_pivotStopLongEntry = entry_price;
            ModifyPositionStopLoss(position_ticket, entry_price, "BreakEven");
            PrintFormat("✅ Regular BreakEven LONG applied at %.1f pips (trigger: %d pips)", dist_in_pips, InpBETriggerPips);
        }
    }
    
    // SHORT POSITION MANAGEMENT (matches Pine Script) 
    else if(position_type == POSITION_TYPE_SELL)
    {
        double pip_to_points_multiplier = GetPipToPointsMultiplier();
        double dist_in_pips = (entry_price - current_price) / (g_point_value * pip_to_points_multiplier);
        
        if(should_debug)
        {
            PrintFormat("SHORT DEBUG: LastEntryLots=%.2f, TpEntry=%.5f, Triggered=%s, Dist=%.1f pips", 
                       g_lastEntryLots, g_pivotTpShortEntry, g_scaleOut1ShortTriggered ? "YES" : "NO", dist_in_pips);
        }
        
        // Scale-out logic for short positions
        if(InpEnableScaleOut && InpScaleOut1Enabled && !g_scaleOut1ShortTriggered && g_pivotTpShortEntry > 0)
        {
            // Calculate scale-out price at specified percentage of the target distance
            double scaleOut1Price = GetPriceAtPctOfRange(entry_price, g_pivotTpShortEntry, InpScaleOut1Pct);
            double tp_distance_points = (entry_price - g_pivotTpShortEntry) / g_point_value;
            double current_progress_pct = ((entry_price - current_price) / (entry_price - g_pivotTpShortEntry)) * 100.0;
            
            if(should_debug)
            {
                PrintFormat("SHORT Scale-Out: TP Distance=%.1f points, ScaleOut@%.5f (%.1f%%), Current Progress=%.1f%%", 
                           tp_distance_points, scaleOut1Price, InpScaleOut1Pct, current_progress_pct);
                PrintFormat("SHORT Scale-Out Trigger Check: Current %.5f <= Target %.5f ? %s", 
                           current_price, scaleOut1Price, current_price <= scaleOut1Price ? "YES - TRIGGER!" : "NO");
            }
            
            // Execute scale-out when price reaches the level
            if(current_price <= scaleOut1Price)
            {
                g_scaleOut1ShortTriggered = true;
                
                // Enhanced volume calculation with debugging
                double scale_out_percentage = InpScaleOut1Size / 100.0;
                double calculated_partial_qty = g_lastEntryLots * scale_out_percentage;
                double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
                double partialQty = MathMax(calculated_partial_qty, min_volume);
                
                // Additional validation: ensure it doesn't exceed current position volume
                partialQty = MathMin(partialQty, position_volume);
                
                PrintFormat("🎯 SCALE-OUT SHORT TRIGGERED! Entry: %.5f, Current: %.5f, Target: %.5f (%.1f%% of %.1f points)", 
                           entry_price, current_price, scaleOut1Price, InpScaleOut1Pct, tp_distance_points);
                PrintFormat("📊 VOLUME CALCULATION: g_lastEntryLots=%.2f * %.1f%% = %.2f, Min=%.2f, Position=%.2f, Final=%.2f", 
                           g_lastEntryLots, InpScaleOut1Size, calculated_partial_qty, min_volume, position_volume, partialQty);
                
                if(PartialClosePosition(partialQty, "Scale-Out"))
                {
                    PrintFormat("✅ Scale-Out SHORT executed: %.2f lots at %.5f (%.1f%% of TP distance)", 
                              partialQty, current_price, InpScaleOut1Pct);
                    
                    // Set breakeven if enabled
                    if(InpScaleOut1BE && !g_beAppliedShort)
                    {
                        g_beAppliedShort = true;
                        g_pivotStopShortEntry = entry_price;
                        ModifyPositionStopLoss(position_ticket, entry_price, "BE_After_ScaleOut");
                    }
                }
                else
                {
                    PrintFormat("❌ Scale-Out SHORT FAILED to execute partial close!");
                }
            }
        }
        else if(should_debug)
        {
            // Debug why scale-out is not being checked
            if(!InpEnableScaleOut) PrintFormat("SHORT Scale-Out DISABLED: InpEnableScaleOut = false");
            if(!InpScaleOut1Enabled) PrintFormat("SHORT Scale-Out DISABLED: InpScaleOut1Enabled = false");
            if(g_scaleOut1ShortTriggered) PrintFormat("SHORT Scale-Out ALREADY TRIGGERED");
            if(g_pivotTpShortEntry <= 0) PrintFormat("SHORT Scale-Out DISABLED: No valid TP stored (g_pivotTpShortEntry = %.5f)", g_pivotTpShortEntry);
        }
        
        // Regular breakeven (separate from scale-out)
        if(InpEnableBreakEven && !g_beAppliedShort && dist_in_pips >= InpBETriggerPips)
        {
            g_beAppliedShort = true;
            g_pivotStopShortEntry = entry_price;
            ModifyPositionStopLoss(position_ticket, entry_price, "BreakEven");
            PrintFormat("✅ Regular BreakEven SHORT applied at %.1f pips (trigger: %d pips)", dist_in_pips, InpBETriggerPips);
        }
    }
}

// Function to modify position stop loss
bool ModifyPositionStopLoss(ulong ticket, double new_sl, string comment)
{
    if(!PositionSelectByTicket(ticket)) return false;
    
    double current_tp = PositionGetDouble(POSITION_TP);
    double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
    
    CTrade trade;
    bool result = trade.PositionModify(ticket, new_sl, current_tp);
    
    if(result)
    {
        PrintFormat("ModifyPositionStopLoss: Position #%d SL modified to %.5f. Comment: %s", 
                  ticket, new_sl, comment);
        
        // CRITICAL FIX: Check if this is a breakeven move (SL = entry price)
        bool is_breakeven = (MathAbs(new_sl - entry_price) <= g_point_value);
        
        if(is_breakeven && (StringFind(comment, "BreakEven") >= 0 || StringFind(comment, "BE_") >= 0))
        {
            // Send special BREAKEVEN command so EA2 can move its SL to its own entry price
            PrintFormat("ModifyPositionStopLoss: Detected breakeven move. Sending BREAKEVEN_HEDGE command for ticket %d", ticket);
            WriteCommandToSlaveFile("BREAKEVEN_HEDGE", ticket, _Symbol, 0, 0, 0, 0);
        }
        else
        {
            // Send normal modification command (slave SL = master TP, slave TP = master SL)
            WriteCommandToSlaveFile("MODIFY_HEDGE", ticket, _Symbol, 0, 0, current_tp, new_sl);
        }
        return true;
    }
    else
    {
        PrintFormat("ModifyPositionStopLoss: Failed to modify position #%d SL. Error: %d", 
                  ticket, GetLastError());
        return false;
    }
}

// Function to restore scale-out tracking for existing positions (when EA is attached to chart with existing trades)
void RestoreScaleOutTrackingForExistingPositions()
{
    Print("RestoreScaleOutTrackingForExistingPositions: Checking for existing positions to restore scale-out tracking...");
    
    int total_positions = PositionsTotal();
    bool found_position = false;
    
    for(int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber &&
               PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                found_position = true;
                double position_volume = PositionGetDouble(POSITION_VOLUME);
                double position_sl = PositionGetDouble(POSITION_SL);
                double position_tp = PositionGetDouble(POSITION_TP);
                double entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
                ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
                
                PrintFormat("RestoreScaleOutTracking: Found existing position #%d (%s), Volume: %.2f, Entry: %.5f, SL: %.5f, TP: %.5f", 
                           ticket, position_type == POSITION_TYPE_BUY ? "LONG" : "SHORT", 
                           position_volume, entry_price, position_sl, position_tp);
                
                // Restore scale-out tracking variables
                g_lastEntryLots = position_volume; // Use current volume as the "original" lot size
                
                if(position_type == POSITION_TYPE_BUY) // LONG
                {
                    g_pivotStopLongEntry = position_sl;
                    g_pivotTpLongEntry = position_tp;
                    
                    // If no TP is set, try to calculate one using current pivot logic
                    if(position_tp == 0.0)
                    {
                        double calculated_sl = CalculateStopLoss(1, entry_price);
                        double calculated_tp = CalculateTakeProfit(1, entry_price, calculated_sl);
                        if(calculated_tp > 0.0)
                        {
                            g_pivotTpLongEntry = calculated_tp;
                            PrintFormat("RestoreScaleOutTracking: No TP found, calculated new TP: %.5f for LONG position (SL: %.5f)", calculated_tp, calculated_sl);
                        }
                        else
                        {
                            PrintFormat("RestoreScaleOutTracking: WARNING - Could not calculate TP for LONG position. Scale-out will be disabled.");
                        }
                    }
                    
                    PrintFormat("RestoreScaleOutTracking: LONG position restored - Lots: %.2f, SL: %.5f, TP: %.5f", 
                               g_lastEntryLots, g_pivotStopLongEntry, g_pivotTpLongEntry);
                }
                else if(position_type == POSITION_TYPE_SELL) // SHORT
                {
                    g_pivotStopShortEntry = position_sl;
                    g_pivotTpShortEntry = position_tp;
                    
                    // If no TP is set, try to calculate one using current pivot logic
                    if(position_tp == 0.0)
                    {
                        double calculated_sl = CalculateStopLoss(-1, entry_price);
                        double calculated_tp = CalculateTakeProfit(-1, entry_price, calculated_sl);
                        if(calculated_tp > 0.0)
                        {
                            g_pivotTpShortEntry = calculated_tp;
                            PrintFormat("RestoreScaleOutTracking: No TP found, calculated new TP: %.5f for SHORT position (SL: %.5f)", calculated_tp, calculated_sl);
                        }
                        else
                        {
                            PrintFormat("RestoreScaleOutTracking: WARNING - Could not calculate TP for SHORT position. Scale-out will be disabled.");
                        }
                    }
                    
                    PrintFormat("RestoreScaleOutTracking: SHORT position restored - Lots: %.2f, SL: %.5f, TP: %.5f", 
                               g_lastEntryLots, g_pivotStopShortEntry, g_pivotTpShortEntry);
                }
                
                // Reset scale-out flags since this is a "new" tracking setup
                ResetScaleOutFlags();
                
                break; // Assume only one position per EA
            }
        }
    }
    
    if(!found_position)
    {
        Print("RestoreScaleOutTracking: No existing positions found for this EA/symbol combination.");
    }
}

//+------------------------------------------------------------------+
//| Symbol Compatibility Helper Functions                            |
//+------------------------------------------------------------------+
string GetEffectiveMasterSymbol()
{
    return (InpMasterSymbolOverride != "") ? InpMasterSymbolOverride : _Symbol;
}

string GetExpectedSlaveSymbol()
{
    return (InpExpectedSlaveSymbol != "") ? InpExpectedSlaveSymbol : _Symbol;
}

string NormalizeSymbol(string symbol)
{
    string normalized = symbol;
    
    // Remove common suffixes
    string suffixes[] = {".p", ".pro", ".c", ".raw", ".ecn", "_", ".m"};
    for(int i = 0; i < ArraySize(suffixes); i++)
    {
        int suffix_pos = StringFind(normalized, suffixes[i]);
        if(suffix_pos > 0 && suffix_pos == StringLen(normalized) - StringLen(suffixes[i]))
        {
            normalized = StringSubstr(normalized, 0, suffix_pos);
            break;
        }
    }
    
    // Remove common prefixes  
    string prefixes[] = {"m", "#", "."};
    for(int i = 0; i < ArraySize(prefixes); i++)
    {
        if(StringFind(normalized, prefixes[i]) == 0)
        {
            normalized = StringSubstr(normalized, StringLen(prefixes[i]));
            break;
        }
    }
    
    return normalized;
}

bool IsSymbolCompatible(string symbol1, string symbol2)
{
    // Direct match
    if(symbol1 == symbol2) return true;
    
    // Normalized match
    if(NormalizeSymbol(symbol1) == NormalizeSymbol(symbol2)) return true;
    
    return false;
}

void LogSymbolCompatibility(string context, string symbol1, string symbol2)
{
    if(!InpEnableSymbolLogging) return;
    
    bool compatible = IsSymbolCompatible(symbol1, symbol2);
    string status = compatible ? "COMPATIBLE" : "MISMATCH";
    
    PrintFormat("SYMBOL %s [%s]: %s vs %s (Normalized: %s vs %s)", 
                context, status, symbol1, symbol2, 
                NormalizeSymbol(symbol1), NormalizeSymbol(symbol2));
}

// --- Scale-Out Tracking Variables (added to match Pine Script) ---

//+------------------------------------------------------------------+
//| EA2 SAFETY VERIFICATION SYSTEM (CRITICAL SAFETY IMPLEMENTATION) |
//+------------------------------------------------------------------+

// Initialize EA2 verification system
void InitializeEA2Verification()
{
    g_ea2_is_verified = false;
    g_ea2_is_connected = false;
    g_ea2_is_receive_mode = false;
    g_ea2_status_update_count = 0;
    g_last_ea2_status_time = 0;
    g_ea2_verification_start_time = TimeCurrent();
    g_ea2_last_status_message = "";
    g_trading_blocked_by_safety = true;
    
    if(InpEnableEA2SafetyLogging)
    {
        PrintFormat("🛡️  EA2 SAFETY VERIFICATION INITIALIZED");
        PrintFormat("   ⚠️  TRADING BLOCKED until EA2 verification complete");
        PrintFormat("   ⏱️  Timeout: %d seconds, Min Updates: %d", InpEA2VerificationTimeoutSec, InpMinEA2StatusUpdates);
    }

    // === ADDED FOR STRATEGY TESTER ===
    if(g_is_tester_mode)
    {
        g_ea2_is_verified = true;
        g_trading_blocked_by_safety = false;
        if(InpEnableEA2SafetyLogging)
        {
            PrintFormat("🛡️  EA2 SAFETY VERIFICATION BYPASSED for Strategy Tester mode. Trading allowed.");
        }
    }
    // === END ADDED FOR STRATEGY TESTER ===
}

// Get comprehensive EA2 verification status
EA2VerificationStatus GetEA2VerificationStatus()
{
    EA2VerificationStatus status;
    
    // Initialize all fields
    status.is_verified = false;
    status.is_connected = g_ea2_is_connected;
    status.is_receive_mode = g_ea2_is_receive_mode;
    status.has_minimum_updates = (g_ea2_status_update_count >= InpMinEA2StatusUpdates);
    status.response_time_ok = true;
    status.last_status_time = g_last_ea2_status_time;
    status.status_update_count = g_ea2_status_update_count;
    status.last_message = g_ea2_last_status_message;
    status.verification_failure_reason = "";
    
    // Check response time
    datetime current_time = TimeCurrent();
    if(g_last_ea2_status_time > 0)
    {
        int time_since_last_update = (int)(current_time - g_last_ea2_status_time);
        if(time_since_last_update > InpEA2VerificationTimeoutSec)
        {
            status.response_time_ok = false;
            status.verification_failure_reason = StringFormat("EA2 timeout: %d sec since last update", time_since_last_update);
        }
    }
    
    // Check overall verification requirements
    if(!InpRequireEA2Verification)
    {
        status.is_verified = true; // Safety disabled by user
        status.verification_failure_reason = "EA2 verification disabled by user";
    }
    else if(!status.is_connected)
    {
        status.verification_failure_reason = "EA2 not connected";
    }
    else if(!status.is_receive_mode)
    {
        status.verification_failure_reason = "EA2 not in receive mode";
    }
    else if(!status.has_minimum_updates)
    {
        status.verification_failure_reason = StringFormat("Insufficient status updates: %d/%d", 
                                                         g_ea2_status_update_count, InpMinEA2StatusUpdates);
    }
    else if(!status.response_time_ok)
    {
        // Already set above
    }
    else
    {
        status.is_verified = true;
        status.verification_failure_reason = "Verified OK";
    }
    
    return status;
}

// Update EA2 verification based on status file
void UpdateEA2VerificationFromStatus(string status_content)
{
    if(!InpRequireEA2Verification) return;
    
    bool previous_verified = g_ea2_is_verified;
    
    // Reset connection status
    g_ea2_is_connected = false;
    g_ea2_is_receive_mode = false;
    
    if(status_content != "")
    {
        g_ea2_is_connected = true;
        g_ea2_status_update_count++;
        g_last_ea2_status_time = TimeCurrent();
        g_ea2_last_status_message = status_content;
        
        // Check if EA2 is in receive mode (look for key indicators)
        if(StringFind(status_content, "Monitoring") != -1 || 
           StringFind(status_content, "Ready") != -1 || 
           StringFind(status_content, "Connected") != -1)
        {
            g_ea2_is_receive_mode = true;
        }
    }
    
    // Update overall verification status
    EA2VerificationStatus verification = GetEA2VerificationStatus();
    g_ea2_is_verified = verification.is_verified;
    g_trading_blocked_by_safety = !g_ea2_is_verified;
    
    // Log status changes
    if(InpEnableEA2SafetyLogging)
    {
        if(!previous_verified && g_ea2_is_verified)
        {
            PrintFormat("✅ EA2 VERIFICATION COMPLETE - Trading now ENABLED");
            PrintFormat("   📊 Status Updates: %d, Connected: %s, Receive Mode: %s", 
                       g_ea2_status_update_count, 
                       g_ea2_is_connected ? "YES" : "NO",
                       g_ea2_is_receive_mode ? "YES" : "NO");
        }
        else if(previous_verified && !g_ea2_is_verified)
        {
            PrintFormat("⚠️  EA2 VERIFICATION LOST - Trading now BLOCKED");
            PrintFormat("   🚫 Reason: %s", verification.verification_failure_reason);
        }
    }
}

// Check if trading is allowed (primary safety check)
bool IsTradingAllowedBySafety()
{
    if(!InpRequireEA2Verification)
    {
        return true; // Safety system disabled
    }
    
    EA2VerificationStatus verification = GetEA2VerificationStatus();
    
    if(!verification.is_verified)
    {
        if(InpEnableEA2SafetyLogging)
        {
            static datetime last_warning_time = 0;
            if(TimeCurrent() - last_warning_time > 30) // Log warning every 30 seconds
            {
                PrintFormat("🚫 TRADING BLOCKED - EA2 Safety Check Failed: %s", verification.verification_failure_reason);
                PrintFormat("   📊 Updates: %d/%d, Connected: %s, Receive Mode: %s, Response Time OK: %s", 
                           verification.status_update_count, InpMinEA2StatusUpdates,
                           verification.is_connected ? "YES" : "NO",
                           verification.is_receive_mode ? "YES" : "NO",
                           verification.response_time_ok ? "YES" : "NO");
                last_warning_time = TimeCurrent();
            }
        }
        return false;
    }
    
    return true;
}

// Verify EA2 is ready for specific trade command
bool VerifyEA2ReadyForCommand(string command_type, ulong master_ticket)
{
    if(!InpRequireEA2Verification)
    {
        return true; // Safety disabled
    }
    
    if(!IsTradingAllowedBySafety())
    {
        PrintFormat("🚫 COMMAND BLOCKED: %s for ticket %d - EA2 not verified", command_type, master_ticket);
        return false;
    }
    
    // Additional checks for specific commands
    if(command_type == "OPEN_LONG" || command_type == "OPEN_SHORT")
    {
        // For opening trades, require recent status update
        int time_since_update = (int)(TimeCurrent() - g_last_ea2_status_time);
        if(time_since_update > 10) // Require update within last 10 seconds
        {
            PrintFormat("🚫 TRADE BLOCKED: %s - EA2 status too old (%d sec)", command_type, time_since_update);
            return false;
        }
    }
    
    if(InpEnableEA2SafetyLogging)
    {
        PrintFormat("✅ EA2 VERIFIED for command: %s (ticket %d)", command_type, master_ticket);
    }
    
    return true;
}

// Force re-verification (reset verification state)
void ForceEA2Reverification()
{
    g_ea2_is_verified = false;
    g_ea2_status_update_count = 0;
    g_ea2_verification_start_time = TimeCurrent();
    g_trading_blocked_by_safety = true;
    
    PrintFormat("🔄 EA2 RE-VERIFICATION FORCED - Trading blocked until EA2 re-verified");
}

// Log comprehensive EA2 safety status
void LogEA2SafetyStatus()
{
    if(!InpEnableEA2SafetyLogging) return;
    
    static datetime last_log_time = 0;
    if(TimeCurrent() - last_log_time < 60) return; // Log every minute max
    
    EA2VerificationStatus verification = GetEA2VerificationStatus();
    
    PrintFormat("🛡️  EA2 SAFETY STATUS REPORT:");
    PrintFormat("   ✅ Overall Verified: %s", verification.is_verified ? "YES" : "NO");
    PrintFormat("   🔌 Connected: %s", verification.is_connected ? "YES" : "NO");
    PrintFormat("   📡 Receive Mode: %s", verification.is_receive_mode ? "YES" : "NO");
    PrintFormat("   📊 Status Updates: %d/%d", verification.status_update_count, InpMinEA2StatusUpdates);
    PrintFormat("   ⏱️  Response Time OK: %s", verification.response_time_ok ? "YES" : "NO");
    PrintFormat("   🚦 Trading Status: %s", verification.is_verified ? "ENABLED" : "BLOCKED");
    
    if(!verification.is_verified)
    {
        PrintFormat("   ⚠️  Failure Reason: %s", verification.verification_failure_reason);
    }
    
    if(verification.last_status_time > 0)
    {
        int seconds_ago = (int)(TimeCurrent() - verification.last_status_time);
        PrintFormat("   📅 Last Update: %d seconds ago", seconds_ago);
        PrintFormat("   📝 Last Message: %s", verification.last_message);
    }
    
    last_log_time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Daily PnL and Cumulative PnL Calculation Support for Dashboard  |
//+------------------------------------------------------------------+

// Daily PnL breakdown structure
struct DailyPnLBreakdown
{
    double total_daily_pnl;      // Total daily P&L
    double realized_daily_pnl;   // Realized P&L from closed trades
    double unrealized_daily_pnl; // Unrealized P&L from open positions
};

// Cumulative PnL structure
struct ComprehensiveCumulativePnL
{
    double total_cumulative_pnl;        // Total cumulative P&L
    double max_drawdown_percentage;     // Maximum drawdown as percentage
    double annualized_return_percentage; // Annualized return percentage
    int trading_days_elapsed;           // Number of trading days
};

// Calculate daily PnL for dashboard
DailyPnLBreakdown CalculateDailyPnL()
{
    DailyPnLBreakdown breakdown;
    
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Total daily PnL using equity change
    breakdown.total_daily_pnl = current_equity - g_prop_equity_at_day_start;
    
    // Realized PnL using balance change
    breakdown.realized_daily_pnl = current_balance - g_prop_balance_at_day_start;
    
    // Unrealized PnL as difference
    breakdown.unrealized_daily_pnl = breakdown.total_daily_pnl - breakdown.realized_daily_pnl;
    
    return breakdown;
}

// Calculate daily realized PnL (for slave/real account support)
double CalculateDailyRealizedPnL(bool is_master_account)
{
    if(is_master_account)
    {
        double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
        return current_balance - g_prop_balance_at_day_start;
    }
    else
    {
        // For slave account, use the daily PnL value we already track
        return g_slave_daily_pnl * 0.7; // Estimate realized portion as 70%
    }
}

// Calculate comprehensive cumulative PnL
ComprehensiveCumulativePnL CalculateComprehensiveCumulativePnL(bool is_master_account)
{
    ComprehensiveCumulativePnL result;
    
    if(is_master_account)
    {
        double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
        double initial_balance = (InpStartingBalanceOverride > 0) ? InpStartingBalanceOverride : 25000.0;
        
        // Simple cumulative PnL calculation
        result.total_cumulative_pnl = current_equity - initial_balance;
        
        // Simple max drawdown calculation
        if(g_prop_highest_equity_peak > 0)
        {
            double current_drawdown = g_prop_highest_equity_peak - current_equity;
            result.max_drawdown_percentage = (current_drawdown / g_prop_highest_equity_peak) * 100.0;
        }
        else
        {
            result.max_drawdown_percentage = 0.0;
        }
        
        // Simple annualized return (estimated)
        if(g_prop_current_trading_days > 0 && initial_balance > 0)
        {
            double period_return = result.total_cumulative_pnl / initial_balance;
            double annualization_factor = 252.0 / g_prop_current_trading_days; // 252 trading days per year
            result.annualized_return_percentage = period_return * annualization_factor * 100.0;
        }
        else
        {
            result.annualized_return_percentage = 0.0;
        }
        
        result.trading_days_elapsed = g_prop_current_trading_days;
    }
    else
    {
        // For slave/real account
        double initial_slave_balance = 1000.0; // Assume starting balance for calculation
        
        result.total_cumulative_pnl = g_slave_equity - initial_slave_balance;
        result.max_drawdown_percentage = 0.0; // Simplified for now
        result.annualized_return_percentage = 0.0; // Simplified for now
        result.trading_days_elapsed = g_prop_current_trading_days; // Use same days as master
    }
    
    return result;
}