// SynPropEA2.mq5
#property copyright "t2an3tos"
#property link      "https://github.com/t2an3tos/SynerProEA"
#property version   "1.00"
#property strict
#property description "Slave EA for Synergy Strategy - Hedge Account"
#property script_show_inputs

#include <Trade\Trade.mqh>

// --- Global Variables & Inputs ---
// File Communication Settings
input string InpMasterCommandFileName = "SynerProEA_Commands.csv";  // File for command communication
input string InpSlaveStatusFile       = "EA2_Status.txt";           // Status file this EA writes to
input string InpMasterStatusFile      = "EA1_Status.txt";           // Master EA status file to read from
input bool   InpUseSharedFolder       = true;                       // Use MT5 shared folder for files
input int    InpUpdateIntervalSeconds = 5;                        // Update interval (0 = tick-based)

// Symbol Compatibility Settings (for broker prefix/suffix handling)
input group  "=== BROKER SYMBOL COMPATIBILITY ===";
input string InpSlaveSymbolOverride   = "";                         // Override slave symbol (leave empty for auto _Symbol)
input string InpExpectedMasterSymbol  = "";                         // Expected master symbol (leave empty for auto)
input bool   InpEnableSymbolLogging   = true;                       // Enable detailed symbol compatibility logging

// Trading Settings
input bool   InpEnableTrading        = true;                      // Enable/disable hedge trading
input int    InpMagicNumber_Slave    = 54321;                     // Magic number for slave EA trades
input string InpMasterTicketCommentPrefix = "Master#";            // Prefix for master ticket tracking
input double InpHedgeMultiplier       = 1.0;                        // Hedge volume multiplier

// Hedge Factor Settings
input double InpChallengeCost_HedgeContext     = 700.0;           // Challenge cost for hedge calculation
input double InpMaxDrawdownProp_HedgeContext  = 4000.0;          // Max drawdown for prop account  
input double InpSlipBufferPercent_HedgeContext = 5.0;             // Slippage buffer percentage

// Hedge Scale-Out Response Settings
input group  "=== HEDGE SCALE-OUT RESPONSE ===";
enum ENUM_HEDGE_SCALEOUT_STRATEGY
{
   HEDGE_SCALEOUT_NONE = 0,           // No response - let hedge run full course
   HEDGE_SCALEOUT_REDUCE = 1,         // Reduce hedge size proportionally
   HEDGE_SCALEOUT_BREAKEVEN = 2,      // Move hedge to breakeven
   HEDGE_SCALEOUT_INVERSE = 3,        // Scale out hedge when it reaches profit
   HEDGE_SCALEOUT_CLOSE_PARTIAL = 4,  // Close same percentage as master
   HEDGE_SCALEOUT_ADAPTIVE = 5        // Adaptive based on hedge P&L
};

input bool   InpEnableHedgeResponse = true;              // Master enable/disable hedge response
input double InpHedgeLossThresholdLow = 15.0;            // Low loss threshold (% of challenge cost)
input double InpHedgeLossThresholdHigh = 50.0;           // High loss threshold (% of challenge cost)  
input double InpHedgeReductionPercentage = 25.0;         // Default reduction percentage
input bool   InpHedgeForceBreakevenOnProfit = true;      // Force BE when master profits

// --- Daily Reset Configuration (added to match user specification) ---
input group  "=== DAILY PNL SETTINGS ===";
input int    InpDailyResetHour = 0;                // Hour for daily reset (0-23)
input int    InpDailyResetMinute = 1;              // Minute for daily reset (1 for 00:01-23:59 period)
input bool   InpEnableDailyPnLLogging = true;     // Enable detailed daily PnL logging

// --- CUMULATIVE PnL TRACKING SYSTEM (NEW) ---
struct CumulativePnLHistory
{
    datetime period_start;           // Period start timestamp
    double equity_start;             // Equity at period start
    double balance_start;            // Balance at period start
    double total_flows;              // Cumulative deposits - withdrawals
    double total_realized_pnl;       // Cumulative realized P&L
    double total_commissions;        // Cumulative commissions/fees
    double total_financing;          // Cumulative swap/financing costs
    double peak_equity;              // Highest equity reached in period
    double max_drawdown_amount;      // Largest equity drawdown from peak
    double max_drawdown_percent;     // Largest % drawdown from peak
    datetime max_drawdown_date;      // When max drawdown occurred
    int trading_days_count;          // Number of trading days in period
};

// Global cumulative tracking
static CumulativePnLHistory g_cumulative_history;
static double g_daily_pnl_array[];               // Historical daily P&L values
static datetime g_daily_dates_array[];           // Corresponding dates
static int g_cumulative_history_size = 0;       // Current history array size
static bool g_cumulative_tracking_initialized = false;

// --- CUMULATIVE PnL SETTINGS (NEW) ---
input group  "=== CUMULATIVE PNL TRACKING ===";
input bool   InpEnableCumulativeTracking = true;  // Enable cumulative P&L tracking
input int    InpMaxHistoryDays = 365;             // Maximum days of history to keep
input bool   InpEnableCumulativeLogging = true;   // Enable cumulative P&L logging
input bool   InpTrackDrawdownDetails = true;      // Track detailed drawdown metrics

// --- Internal Global Variables ---
CTrade trade;
string g_ea_status_string = "Initializing...";
string g_last_cmd_processed_str = "None";
datetime g_last_processed_cmd_timestamp = 0;
datetime g_last_day_for_daily_reset_slave = 0;
double g_slave_balance_at_day_start = 0.0;
double g_slave_equity_at_day_start = 0.0;          // ADDED: Critical fix for proper daily PnL calculation
double g_point_value = 0.0;
int g_digits_value = 0;
string g_csv_delimiter = ",";

// File handles
int g_master_command_file_handle = INVALID_HANDLE;
int g_slave_status_file_handle = INVALID_HANDLE;

// Master EA indicator values
double g_master_total_synergy = 0.0;
double g_master_synergy_m5 = 0.0;
double g_master_synergy_m15 = 0.0;
double g_master_synergy_h1 = 0.0;
double g_master_adx_main = 0.0;
double g_master_adx_plus = 0.0;
double g_master_adx_minus = 0.0;
double g_master_adx_threshold = 0.0;
double g_master_ha_bias = 0.0;
bool g_master_session_active = false;
datetime g_master_status_timestamp = 0;

// Mini dashboard
string g_mini_dash_prefix = "SynProp2_";

// --- Debug Message Throttling Variables ---
static datetime g_last_command_debug_log_time = 0;
static datetime g_last_sync_debug_log_time = 0;
static datetime g_last_status_debug_log_time = 0;
static datetime g_last_master_read_debug_log_time = 0;
const int DEBUG_PRINT_THROTTLE_SECONDS = 60; // 1 minute throttling for debug messages

// Global variables for challenge cost and thresholds
double g_challenge_cost = 700.0;                         // Will be updated from master EA
double g_hedge_loss_threshold_low_dollars = 0.0;         // Calculated from percentage
double g_hedge_loss_threshold_high_dollars = 0.0;        // Calculated from percentage
double g_current_hedge_pnl = 0.0;                        // Current hedge P&L for dashboard
double g_hedge_loss_percentage = 0.0;                    // Hedge loss as % of challenge cost

// --- EA2 STATUS REPORTING SYSTEM (FOR EA1 SAFETY VERIFICATION) ---
input group  "=== EA2 STATUS REPORTING ===";
input bool   InpEnableStatusReporting = true;         // Enable status reporting to EA1
input int    InpStatusUpdateIntervalSec = 5;          // Status update interval (seconds)
input bool   InpEnableDetailedStatusLogs = true;      // Enable detailed status logging

// --- EA2 STATUS TRACKING VARIABLES ---
static datetime g_last_status_update_time = 0;        // Last status update timestamp
static bool g_ea2_is_monitoring = false;              // EA2 monitoring status
static bool g_ea2_is_ready = false;                   // EA2 ready status
static int g_status_update_counter = 0;               // Status update counter
static string g_ea2_current_status = "Initializing";  // Current status message

// EA2 status structure
struct EA2StatusInfo
{
    bool is_monitoring;                    // EA2 is monitoring commands
    bool is_ready;                        // EA2 is ready to receive commands
    bool is_connected;                    // EA2 is connected and functional
    string status_message;                // Current status message
    datetime last_update_time;            // Last status update time
    int update_counter;                   // Number of status updates sent
    double balance;                       // Current balance
    double equity;                        // Current equity
    string server;                        // Server name
    int leverage;                         // Account leverage
};

int      g_min_bars_needed_for_ea = 100;

//+------------------------------------------------------------------+
//| Symbol Compatibility Helper Functions                            |
//+------------------------------------------------------------------+
string GetEffectiveSlaveSymbol()
{
    return (InpSlaveSymbolOverride != "") ? InpSlaveSymbolOverride : _Symbol;
}

string GetExpectedMasterSymbol()
{
    return (InpExpectedMasterSymbol != "") ? InpExpectedMasterSymbol : _Symbol;
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

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    g_point_value = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
    g_digits_value = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
    trade.SetExpertMagicNumber(InpMagicNumber_Slave);
    trade.SetDeviationInPoints(5);
    trade.SetTypeFillingBySymbol(_Symbol);

    MqlDateTime temp_dt;
    TimeToStruct(TimeCurrent(), temp_dt);
    temp_dt.hour = 0;
    temp_dt.min = 0;
    temp_dt.sec = 0;
    g_last_day_for_daily_reset_slave = StructToTime(temp_dt);
    g_slave_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE);
    g_slave_equity_at_day_start = AccountInfoDouble(ACCOUNT_EQUITY);

    Dashboard_Mini_Init();
    
    // Initialize EA2 status reporting system (CRITICAL FOR EA1 SAFETY)
    InitializeEA2StatusReporting();
    
    // Initialize cumulative PnL tracking system
    InitializeCumulativeTracking();
    
    UpdateAndWriteSlaveStatusFile(true, "Initialized");
    UpdateMiniDashboard();

    if(InpUpdateIntervalSeconds > 0)
    {
        EventSetTimer(InpUpdateIntervalSeconds);
    }
    else
    {
        Print("Update interval is 0, EA will only process on new ticks if not using timer.");
    }
    
    Print("File operations for inter-EA communication will use the common shared directory (FILE_COMMON).");
    Print("SynPropEA2: Performing startup synchronization...");
    PerformStartupSynchronization();
        
    PrintFormat("SynPropEA2 (Slave) Initialized. Version: %s. Master Command File: '%s', Slave Status File: '%s'",
                "1.00", InpMasterCommandFileName, InpSlaveStatusFile);

    // Set monitoring status to indicate EA2 is ready
    SetEA2MonitoringStatus(true);
    ForceStatusUpdateToEA1("Initialization Complete");

    Comment("SynPropEA2 Initialized. Waiting for master commands...");
   
   // Initialize challenge cost and thresholds
   UpdateChallengeCostAndThresholds(InpChallengeCost_HedgeContext);
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    if(InpUpdateIntervalSeconds > 0)
    {
        EventKillTimer();
    }
    Dashboard_Mini_Deinit();
    Print("SynPropEA2 (Slave) Deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                            |
//+------------------------------------------------------------------+
void OnTick()
{
    // Process new commands from master
    ProcessMasterCommandFile();
    
    // Update hedge P&L for dashboard (every tick when position is open)
    UpdateCurrentHedgePnL();
    
    // Send regular status updates to EA1 (for safety verification)
    SendStatusUpdateToEA1();
    
    // Write status file for master to read (correct function name)
    UpdateAndWriteSlaveStatusFile(true, "Monitoring");
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
    if(InpUpdateIntervalSeconds > 0)
    {
            CheckForNewDay();
    LogDailyPnLBreakdown();  // ADDED: Enhanced daily PnL monitoring
    LogComprehensiveCumulativePnL();  // ADDED: Cumulative PnL monitoring
    ProcessMasterCommandFile();
        ReadMasterStatusFile();
        
        // Send status updates to EA1 (for safety verification)
        SendStatusUpdateToEA1();
        LogEA2StatusForDebugging();
        
        UpdateAndWriteSlaveStatusFile(true, g_ea_status_string);
        UpdateMiniDashboard();
    }
}

//+------------------------------------------------------------------+
//| Check for a new trading day (FIXED: 00:01-23:59 period)        |
//+------------------------------------------------------------------+
void CheckForNewDay()
{
    MqlDateTime current_time_struct;
    TimeToStruct(TimeCurrent(), current_time_struct);
    
    // Create day boundary at configurable time (default 00:01:00 for 00:01-23:59 period)
    MqlDateTime day_boundary_struct = current_time_struct;
    day_boundary_struct.hour = InpDailyResetHour;
    day_boundary_struct.min = InpDailyResetMinute;
    day_boundary_struct.sec = 0;
    datetime day_boundary = StructToTime(day_boundary_struct);

    if(day_boundary > g_last_day_for_daily_reset_slave)
    {
        // CRITICAL FIX: Capture both balance AND equity at day boundary for proper daily PnL calculation
        double previous_balance = g_slave_balance_at_day_start;
        double previous_equity = g_slave_equity_at_day_start;
        
        // Calculate previous day's PnL before reset
        double previous_day_pnl = AccountInfoDouble(ACCOUNT_EQUITY) - previous_equity;
        
        g_slave_balance_at_day_start = AccountInfoDouble(ACCOUNT_BALANCE);
        g_slave_equity_at_day_start = AccountInfoDouble(ACCOUNT_EQUITY);
        g_last_day_for_daily_reset_slave = day_boundary;
        
        // Update cumulative tracking with yesterday's daily PnL
        UpdateCumulativeTracking(previous_day_pnl);
        
        if(InpEnableDailyPnLLogging)
        {
            PrintFormat("🕐 DAILY RESET at %s - Balance: %.2f->%.2f, Equity: %.2f->%.2f, Daily PnL: %.2f", 
                       TimeToString(day_boundary, TIME_DATE|TIME_MINUTES), 
                       previous_balance, g_slave_balance_at_day_start,
                       previous_equity, g_slave_equity_at_day_start, previous_day_pnl);
        }
    }
}

//+------------------------------------------------------------------+
//| Enhanced Daily PnL Calculation Functions (MATHEMATICAL FIX)     |
//+------------------------------------------------------------------+

// Core daily PnL using equity-based approach (matches user's formula)
double CalculateDailyPnL()
{
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double equity_change = current_equity - g_slave_equity_at_day_start;
    
    // Note: In prop trading, deposits/withdrawals are typically zero
    // If needed, subtract: (withdrawals - deposits) from equity_change
    return equity_change;
}

// Realized PnL component (closed trades only)
double CalculateDailyRealizedPnL()
{
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    return current_balance - g_slave_balance_at_day_start;  // Balance change = realized P&L
}

// Unrealized PnL component (mark-to-market on open positions)
double CalculateDailyUnrealizedPnL()
{
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double equity_at_start = g_slave_equity_at_day_start;
    double balance_at_start = g_slave_balance_at_day_start;
    
    // Current unrealized = (Current Equity - Current Balance)
    // Starting unrealized = (Starting Equity - Starting Balance)
    // Daily unrealized change = Current unrealized - Starting unrealized
    return (current_equity - current_balance) - (equity_at_start - balance_at_start);
}

// Comprehensive breakdown following the mathematical reference
struct DailyPnLBreakdown
{
    double total_pnl;           // Total daily P&L
    double realized_pnl;        // Σ(closed trades) 
    double unrealized_pnl;      // Σ(mark-to-market on open positions)
    double commission_costs;    // Σ(commissions/fees) - estimated from spread
    double financing_costs;     // Σ(swap/rollover costs) - if applicable
    double net_flows;           // (Withdrawals - Deposits) - typically 0 in prop trading
    double equity_start;        // Starting equity (BOD)
    double equity_current;      // Current equity
    double balance_start;       // Starting balance (BOD)
    double balance_current;     // Current balance
};

DailyPnLBreakdown GetComprehensiveDailyPnL()
{
    DailyPnLBreakdown breakdown;
    
    // Core values
    breakdown.equity_start = g_slave_equity_at_day_start;
    breakdown.equity_current = AccountInfoDouble(ACCOUNT_EQUITY);
    breakdown.balance_start = g_slave_balance_at_day_start;
    breakdown.balance_current = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Component calculations (following mathematical reference)
    breakdown.realized_pnl = CalculateDailyRealizedPnL();
    breakdown.unrealized_pnl = CalculateDailyUnrealizedPnL();
    breakdown.commission_costs = 0.0;  // Would need detailed trade history to calculate precisely
    breakdown.financing_costs = 0.0;   // Would need swap/rollover tracking
    breakdown.net_flows = 0.0;         // Typically zero in prop trading
    
    // Total using equity-based approach (most reliable)
    breakdown.total_pnl = breakdown.equity_current - breakdown.equity_start - breakdown.net_flows;
    
    return breakdown;
}

void LogDailyPnLBreakdown()
{
    if(!InpEnableDailyPnLLogging) return;
    
    static datetime last_log_time = 0;
    if(TimeCurrent() - last_log_time < 300) return; // Log every 5 minutes max
    
    DailyPnLBreakdown breakdown = GetComprehensiveDailyPnL();
    
    PrintFormat("📊 COMPREHENSIVE DAILY PnL BREAKDOWN:");
    PrintFormat("   📈 Total Daily P&L: %.2f", breakdown.total_pnl);
    PrintFormat("   💰 Realized P&L: %.2f (from closed trades)", breakdown.realized_pnl);
    PrintFormat("   📊 Unrealized P&L: %.2f (mark-to-market)", breakdown.unrealized_pnl);
    PrintFormat("   💵 Account State: Balance %.2f->%.2f, Equity %.2f->%.2f", 
                breakdown.balance_start, breakdown.balance_current,
                breakdown.equity_start, breakdown.equity_current);
    
    // Validation check (realized + unrealized should approximately equal total)
    double component_sum = breakdown.realized_pnl + breakdown.unrealized_pnl;
    double validation_diff = MathAbs(breakdown.total_pnl - component_sum);
    if(validation_diff > 0.01) // More than 1 cent difference
    {
        PrintFormat("⚠️  VALIDATION WARNING: Component sum (%.2f) != Total (%.2f), Diff: %.2f", 
                   component_sum, breakdown.total_pnl, validation_diff);
    }
    else
    {
        PrintFormat("✅ VALIDATION PASSED: Components sum correctly to total");
    }
    
    last_log_time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Perform Startup Synchronization                                 |
//+------------------------------------------------------------------+
void PerformStartupSynchronization()
{
    Print("PerformStartupSynchronization: STARTING...");
    
    if(InpMasterCommandFileName == "")
    {
        Print("PerformStartupSynchronization: No master command file specified. Skipping sync.");
        return;
    }

    int file_handle = FileOpen(InpMasterCommandFileName, FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON, g_csv_delimiter);
    if(file_handle == INVALID_HANDLE)
    {
        bool should_print_sync_debug = (TimeCurrent() - g_last_sync_debug_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
        if(should_print_sync_debug)
        {
            PrintFormat("PerformStartupSynchronization: Could not open command file '%s'. Sync skipped. Error: %d", 
                        InpMasterCommandFileName, GetLastError());
            g_last_sync_debug_log_time = TimeCurrent();
        }
        return;
    }

    // Store all commands from the file
    string all_commands[][8]; // cmd_type, master_ticket, symbol, lots, entry, sl, tp, timestamp
    int command_count = 0;
    
    while(!FileIsEnding(file_handle))
    {
        string cmd_type = FileReadString(file_handle);
        string master_ticket_str = FileReadString(file_handle);
        string symbol_str = FileReadString(file_handle);
        string lots_str = FileReadString(file_handle);
        string entry_str = FileReadString(file_handle); 
        string sl_str = FileReadString(file_handle);
        string tp_str = FileReadString(file_handle);
        string cmd_timestamp_str = FileReadString(file_handle);
        
        if(!FileIsLineEnding(file_handle) && !FileIsEnding(file_handle))
        {
            Print("PerformStartupSynchronization: Incomplete line in command file. Stopping sync.");
            break;
        }
        
        // Store this command
        ArrayResize(all_commands, command_count + 1);
        all_commands[command_count][0] = cmd_type;
        all_commands[command_count][1] = master_ticket_str;
        all_commands[command_count][2] = symbol_str;
        all_commands[command_count][3] = lots_str;
        all_commands[command_count][4] = entry_str;
        all_commands[command_count][5] = sl_str;
        all_commands[command_count][6] = tp_str;
        all_commands[command_count][7] = cmd_timestamp_str;
        command_count++;
    }
    FileClose(file_handle);
    
    if(command_count == 0)
    {
        Print("PerformStartupSynchronization: No commands found in file. Sync complete.");
        g_last_processed_cmd_timestamp = 0;
        return;
    }

    // Find the latest timestamp to set our reference point
    datetime latest_timestamp = 0;
    for(int i = 0; i < command_count; i++)
    {
        datetime cmd_time = (datetime)StringToInteger(all_commands[i][7]);
        if(cmd_time > latest_timestamp)
            latest_timestamp = cmd_time;
    }

    // Process recent MODIFY_HEDGE and BREAKEVEN_HEDGE commands
    datetime sync_cutoff_time = latest_timestamp - 600; // 10 minutes ago
    int modifications_applied = 0;
    
    for(int i = 0; i < command_count; i++)
    {
        string cmd_type = all_commands[i][0];
        datetime cmd_time = (datetime)StringToInteger(all_commands[i][7]);
        
        if((cmd_type == "MODIFY_HEDGE" || cmd_type == "BREAKEVEN_HEDGE") && cmd_time >= sync_cutoff_time)
        {
            ulong master_ticket = (ulong)StringToInteger(all_commands[i][1]);
            
            if(cmd_type == "MODIFY_HEDGE")
            {
                double new_slave_sl = StringToDouble(all_commands[i][5]);
                double new_slave_tp = StringToDouble(all_commands[i][6]);
                
                ulong slave_ticket = FindSlavePositionByMasterTicket(master_ticket);
                if(slave_ticket > 0 && PositionSelectByTicket(slave_ticket))
                {
                    if(trade.PositionModify(slave_ticket, new_slave_sl, new_slave_tp))
                    {
                        modifications_applied++;
                        PrintFormat("PerformStartupSynchronization: Applied MODIFY_HEDGE for ticket %d", slave_ticket);
                    }
                }
            }
            else if(cmd_type == "BREAKEVEN_HEDGE")
            {
                ulong slave_ticket = FindSlavePositionByMasterTicket(master_ticket);
                if(slave_ticket > 0 && PositionSelectByTicket(slave_ticket))
                {
                    double slave_entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
                    double current_tp = PositionGetDouble(POSITION_TP);
                    
                    if(trade.PositionModify(slave_ticket, slave_entry_price, current_tp))
                    {
                        modifications_applied++;
                        PrintFormat("PerformStartupSynchronization: Applied BREAKEVEN_HEDGE for ticket %d", slave_ticket);
                    }
                }
            }
        }
    }
    
    g_last_processed_cmd_timestamp = latest_timestamp;
    PrintFormat("PerformStartupSynchronization: COMPLETE. Applied %d modifications. Set reference timestamp to %s", 
                modifications_applied, TimeToString(g_last_processed_cmd_timestamp));
}

//+------------------------------------------------------------------+
//| Process Master Command File                                      |
//+------------------------------------------------------------------+
void ProcessMasterCommandFile()
{
    if(InpMasterCommandFileName == "")
    {
        g_ea_status_string = "Cmd File N/A";
        return;
    }

    g_master_command_file_handle = FileOpen(InpMasterCommandFileName, FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON, g_csv_delimiter);
    if(g_master_command_file_handle == INVALID_HANDLE)
    {
        static datetime last_error_log_time = 0;
        if(TimeCurrent() - last_error_log_time > 60)
        {
            PrintFormat("ProcessMasterCommandFile: Error opening command file '%s'. Error: %d", InpMasterCommandFileName, GetLastError());
            last_error_log_time = TimeCurrent();
        }
        g_ea_status_string = "Cmd File Read Err";
        return;
    }

    FileSeek(g_master_command_file_handle, 0, SEEK_SET);
    
    bool found_any_new_commands = false;
    int commands_processed = 0;

    while(!FileIsEnding(g_master_command_file_handle))
    {
        string cmd_type = FileReadString(g_master_command_file_handle);
        string master_ticket_str = FileReadString(g_master_command_file_handle);
        string symbol_str = FileReadString(g_master_command_file_handle);
        string lots_str = FileReadString(g_master_command_file_handle);
        string entry_str = FileReadString(g_master_command_file_handle); 
        string sl_str = FileReadString(g_master_command_file_handle);
        string tp_str = FileReadString(g_master_command_file_handle);
        string cmd_timestamp_str = FileReadString(g_master_command_file_handle);
        
        if(!FileIsLineEnding(g_master_command_file_handle) && !FileIsEnding(g_master_command_file_handle))
        {
            Print("ProcessMasterCommandFile: Incomplete line read from command file. Skipping rest of file.");
            break; 
        }

        datetime cmd_timestamp_dt = (datetime)StringToInteger(cmd_timestamp_str);
        int command_age_seconds = (int)(TimeCurrent() - cmd_timestamp_dt);
        bool command_too_old = (command_age_seconds > 1800); // 30 minutes

        if(cmd_timestamp_dt > g_last_processed_cmd_timestamp && !command_too_old)
        {
            found_any_new_commands = true;
            commands_processed++;
            ulong master_ticket = (ulong)StringToInteger(master_ticket_str);

            PrintFormat("ProcessMasterCommandFile: New Command - Type: %s, MasterTicket: %d, Symbol: %s",
                        cmd_type, master_ticket, symbol_str);
            g_last_cmd_processed_str = cmd_type + " @ " + TimeToString(cmd_timestamp_dt, TIME_SECONDS);

            if(InpEnableTrading)
            {
                if(cmd_type == "OPEN_LONG" || cmd_type == "OPEN_SHORT")
                {
                    ulong existing_slave_ticket = FindSlavePositionByMasterTicket(master_ticket);
                    if(existing_slave_ticket > 0)
                    {
                        PrintFormat("ProcessMasterCommandFile: Slave trade for master ticket %d already exists. Skipping.", master_ticket);
                        g_ea_status_string = "Dup OPEN Skip";
                    }
                    else
                    {
                        double lots = StringToDouble(lots_str);
                        double master_sl_from_file = StringToDouble(sl_str);
                        double master_tp_from_file = StringToDouble(tp_str);
                        ExecuteHedgeTrade(cmd_type, symbol_str, lots, master_tp_from_file, master_sl_from_file, master_ticket);
                    }
                }
                else if(cmd_type == "CLOSE_HEDGE")
                {
                    ulong slave_ticket_to_close = FindSlavePositionByMasterTicket(master_ticket);
                    if(slave_ticket_to_close > 0)
                    {
                        if(trade.PositionClose(slave_ticket_to_close))
                        {
                            PrintFormat("ProcessMasterCommandFile: CLOSE_HEDGE successful for master ticket %d", master_ticket);
                            g_ea_status_string = "Hedge Closed";
                        }
                        else
                        {
                            PrintFormat("ProcessMasterCommandFile: Failed to close slave ticket %d", slave_ticket_to_close);
                            g_ea_status_string = "Hedge Close Fail";
                        }
                    }
                    else
                    {
                        PrintFormat("ProcessMasterCommandFile: CLOSE_HEDGE - no slave position found for master ticket %d", master_ticket);
                        g_ea_status_string = "Close: Slave N/F";
                    }
                }
                else if(cmd_type == "MODIFY_HEDGE")
                {
                    double new_slave_sl = StringToDouble(sl_str);
                    double new_slave_tp = StringToDouble(tp_str);
                    
                    ulong slave_ticket_to_modify = FindSlavePositionByMasterTicket(master_ticket);
                    if(slave_ticket_to_modify > 0 && PositionSelectByTicket(slave_ticket_to_modify))
                    {
                        if(trade.PositionModify(slave_ticket_to_modify, new_slave_sl, new_slave_tp))
                        {
                            PrintFormat("ProcessMasterCommandFile: MODIFY_HEDGE successful for slave ticket %d", slave_ticket_to_modify);
                            g_ea_status_string = "Hedge Modified";
                        }
                        else
                        {
                            PrintFormat("ProcessMasterCommandFile: Failed to modify slave ticket %d", slave_ticket_to_modify);
                            g_ea_status_string = "Hedge Mod Fail";
                        }
                    }
                    else
                    {
                        PrintFormat("ProcessMasterCommandFile: MODIFY_HEDGE - no slave position found for master ticket %d", master_ticket);
                        g_ea_status_string = "Modify: Slave N/F";
                    }
                }
                else if(cmd_type == "BREAKEVEN_HEDGE")
                {
                    ulong slave_ticket_to_modify = FindSlavePositionByMasterTicket(master_ticket);
                    if(slave_ticket_to_modify > 0 && PositionSelectByTicket(slave_ticket_to_modify))
                    {
                        double slave_entry_price = PositionGetDouble(POSITION_PRICE_OPEN);
                        double current_tp = PositionGetDouble(POSITION_TP);
                        
                        if(trade.PositionModify(slave_ticket_to_modify, slave_entry_price, current_tp))
                        {
                            PrintFormat("ProcessMasterCommandFile: BREAKEVEN_HEDGE successful for slave ticket %d", slave_ticket_to_modify);
                            g_ea_status_string = "Hedge BE Applied";
                        }
                        else
                        {
                            PrintFormat("ProcessMasterCommandFile: Failed to apply BREAKEVEN_HEDGE for slave ticket %d", slave_ticket_to_modify);
                            g_ea_status_string = "Hedge BE Failed";
                        }
                    }
                    else
                    {
                        PrintFormat("ProcessMasterCommandFile: BREAKEVEN_HEDGE - no slave position found for master ticket %d", master_ticket);
                        g_ea_status_string = "BE: Slave N/F";
                    }
                }
                else if(cmd_type == "SCALEOUT_HEDGE")
                {
                    // Handle master scale-out with intelligent hedge response
                    double master_scaled_volume = StringToDouble(lots_str);
                    double master_scaleout_price = StringToDouble(entry_str);
                    double master_tp_distance_pct = StringToDouble(sl_str);
                    
                    // Strategy info is in the 8th field (index 7) - may need to read additional field
                    string strategy_info = "";
                    if(!FileIsLineEnding(g_master_command_file_handle) && !FileIsEnding(g_master_command_file_handle))
                    {
                        strategy_info = FileReadString(g_master_command_file_handle);
                    }
                    
                    bool hedge_response_result = ExecuteHedgeScaleoutResponse(master_ticket, master_scaled_volume, 
                                                                           master_scaleout_price, master_tp_distance_pct, 
                                                                           strategy_info);
                    
                    if(hedge_response_result)
                    {
                        g_ea_status_string = "Hedge ScaleOut OK";
                    }
                    else
                    {
                        g_ea_status_string = "Hedge ScaleOut Fail";
                    }
                }
            }
            else
            {
                Print("ProcessMasterCommandFile: Trading disabled. Command not executed.");
                g_ea_status_string = "Trading Disabled";
            }
            g_last_processed_cmd_timestamp = cmd_timestamp_dt;
            
            // Send status update after processing command
            ForceStatusUpdateToEA1(StringFormat("Processed %s", cmd_type));
        }
    }
    
    FileClose(g_master_command_file_handle);
    g_master_command_file_handle = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| Calculate Slave Lot Size based on Hedge Factor                   |
//+------------------------------------------------------------------+
double CalculateSlaveLotSize(double master_lots, string for_symbol)
{
    if(InpMaxDrawdownProp_HedgeContext <= 0)
    {
        static datetime last_warning_time = 0;
        if(TimeCurrent() - last_warning_time >= DEBUG_PRINT_THROTTLE_SECONDS)
        {
            PrintFormat("CalculateSlaveLotSize: InpMaxDrawdownProp_HedgeContext (%.2f) is zero or negative. Defaulting to master lots.", 
                        InpMaxDrawdownProp_HedgeContext);
            last_warning_time = TimeCurrent();
        }
        return master_lots;
    }

    double slip_buffer_decimal = InpSlipBufferPercent_HedgeContext / 100.0;
    double challenge_cost_with_buffer = InpChallengeCost_HedgeContext * (1.0 + slip_buffer_decimal);
    
    double hedge_factor = MathMin(1.0, challenge_cost_with_buffer / InpMaxDrawdownProp_HedgeContext);
    double raw_slave_lot = master_lots * hedge_factor;
    
    // Normalize the lot size
    double min_lot = SymbolInfoDouble(for_symbol, SYMBOL_VOLUME_MIN);
    double max_lot = SymbolInfoDouble(for_symbol, SYMBOL_VOLUME_MAX);
    double lot_step = SymbolInfoDouble(for_symbol, SYMBOL_VOLUME_STEP);

    if(lot_step == 0) lot_step = min_lot > 0 ? min_lot : 0.01;
    
    double normalized_lot = MathRound(raw_slave_lot / lot_step) * lot_step;
    normalized_lot = MathMax(normalized_lot, min_lot);
    normalized_lot = MathMin(normalized_lot, max_lot);
    
    static datetime last_calc_debug_time = 0;
    if(TimeCurrent() - last_calc_debug_time >= DEBUG_PRINT_THROTTLE_SECONDS)
    {
        PrintFormat("CalculateSlaveLotSize: MasterLots=%.2f, HedgeFactor=%.4f, NormalizedLot=%.2f",
                    master_lots, hedge_factor, normalized_lot);
        last_calc_debug_time = TimeCurrent();
    }
                
    return normalized_lot;
}

//+------------------------------------------------------------------+
//| Execute Hedge Trade                                              |
//+------------------------------------------------------------------+
bool ExecuteHedgeTrade(string master_cmd_type, string symbol, double master_lots_received, 
                       double hedge_sl_price, double hedge_tp_price, ulong master_ticket)
{
    // Symbol compatibility check using new helper functions
    string effective_slave_symbol = GetEffectiveSlaveSymbol();
    string expected_master_symbol = GetExpectedMasterSymbol();
    
    // Log symbol compatibility
    LogSymbolCompatibility("SLAVE EXEC", symbol, effective_slave_symbol);
    
    // Check if symbols are compatible (not exactly equal due to broker differences)
    bool symbols_compatible = IsSymbolCompatible(symbol, effective_slave_symbol);
    
    if(!symbols_compatible && InpEnableSymbolLogging)
    {
        PrintFormat("⚠️ SYMBOL WARNING: Master symbol '%s' may not be compatible with slave symbol '%s'", 
                   symbol, effective_slave_symbol);
        PrintFormat("   Normalized: Master='%s' vs Slave='%s'", 
                   NormalizeSymbol(symbol), NormalizeSymbol(effective_slave_symbol));
        PrintFormat("   Trade will use slave symbol '%s' for execution", effective_slave_symbol);
    }
    
    ENUM_ORDER_TYPE slave_order_type;
    if(master_cmd_type == "OPEN_LONG")
    {
        slave_order_type = ORDER_TYPE_SELL; // Hedge for master's long is a short
    }
    else if(master_cmd_type == "OPEN_SHORT")
    {
        slave_order_type = ORDER_TYPE_BUY;  // Hedge for master's short is a long
    }
    else
    {
        Print("ExecuteHedgeTrade: Unknown master command type: ", master_cmd_type);
        g_ea_status_string = "Unknown Cmd Type";
        return false;
    }

    // Use effective slave symbol for lot size calculation and trade execution
    double calculated_slave_lots = CalculateSlaveLotSize(master_lots_received, effective_slave_symbol);

    if(calculated_slave_lots <= 0)
    {
        PrintFormat("ExecuteHedgeTrade: Calculated slave lot size is %.2f. No trade will be placed.", calculated_slave_lots);
        g_ea_status_string = "Slave Lot Zero";
        return false;
    }

    string comment = InpMasterTicketCommentPrefix + IntegerToString((long)master_ticket);
    
    bool result = false;
    if(slave_order_type == ORDER_TYPE_BUY)
    {
        result = trade.Buy(calculated_slave_lots, effective_slave_symbol, 0, hedge_sl_price, hedge_tp_price, comment);
    }
    else if(slave_order_type == ORDER_TYPE_SELL)
    {
        result = trade.Sell(calculated_slave_lots, effective_slave_symbol, 0, hedge_sl_price, hedge_tp_price, comment);
    }

    if(result)
    {
        ulong created_ticket = trade.ResultOrder();
        PrintFormat("ExecuteHedgeTrade: SUCCESS. %s executed for %.2f lots on %s. MasterTicket: %d, SlaveTicket: %d",
                    EnumToString(slave_order_type), calculated_slave_lots, effective_slave_symbol, master_ticket, created_ticket);
        g_ea_status_string = EnumToString(slave_order_type) + " Sent (" + DoubleToString(calculated_slave_lots,2) + "L)";
    }
    else
    {
        uint retcode = trade.ResultRetcode();
        PrintFormat("ExecuteHedgeTrade: FAILED to execute %s for %.2f lots on %s. Retcode: %d",
                    EnumToString(slave_order_type), calculated_slave_lots, effective_slave_symbol, retcode);
        g_ea_status_string = "Hedge Exec Fail";
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Find Slave Position by Master Ticket in Comment                  |
//+------------------------------------------------------------------+
ulong FindSlavePositionByMasterTicket(ulong master_ticket_to_find)
{
    string search_comment = InpMasterTicketCommentPrefix + IntegerToString((long)master_ticket_to_find);
    
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong pos_ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(pos_ticket))
        {
            string pos_comment = PositionGetString(POSITION_COMMENT);
            long pos_magic = PositionGetInteger(POSITION_MAGIC);
            
            if(pos_magic == InpMagicNumber_Slave && pos_comment == search_comment)
            {
                return pos_ticket;
            }
        }
    }
    return 0;
}

//+------------------------------------------------------------------+
//| Update and Write Slave Status File                               |
//+------------------------------------------------------------------+
void UpdateAndWriteSlaveStatusFile(bool is_connected_override, string status_text_override)
{
    if(InpSlaveStatusFile == "") return;

    g_slave_status_file_handle = FileOpen(InpSlaveStatusFile, FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_COMMON, g_csv_delimiter);
    if(g_slave_status_file_handle == INVALID_HANDLE)
    {
        bool should_print_status_debug = (TimeCurrent() - g_last_status_debug_log_time >= DEBUG_PRINT_THROTTLE_SECONDS);
        if(should_print_status_debug)
        {
            PrintFormat("UpdateAndWriteSlaveStatusFile: Error opening status file '%s'. Error: %d", InpSlaveStatusFile, GetLastError());
            g_last_status_debug_log_time = TimeCurrent();
        }
        return;
    }

    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double daily_pnl = CalculateDailyPnL();  // FIXED: Use corrected calculation function
    long acc_num = AccountInfoInteger(ACCOUNT_LOGIN);
    string acc_curr = AccountInfoString(ACCOUNT_CURRENCY);
    string is_connected_str = is_connected_override ? "true" : "false";
    datetime current_timestamp = TimeCurrent();
    
    // Get current open volume
    double current_open_volume = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--)
    {
        ulong pos_ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(pos_ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber_Slave)
            {
                current_open_volume += PositionGetDouble(POSITION_VOLUME);
            }
        }
    }
    
    int leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
    string server = AccountInfoString(ACCOUNT_SERVER);

    // Format: Balance,Equity,DailyPnL,AccountNumber,AccountCurrency,StatusText,IsConnected,FileTimestamp,OpenVolume,Leverage,Server
    FileWrite(g_slave_status_file_handle, DoubleToString(current_balance, 2));
    FileWrite(g_slave_status_file_handle, DoubleToString(current_equity, 2));
    FileWrite(g_slave_status_file_handle, DoubleToString(daily_pnl, 2));
    FileWrite(g_slave_status_file_handle, IntegerToString(acc_num));
    FileWrite(g_slave_status_file_handle, acc_curr);
    FileWrite(g_slave_status_file_handle, status_text_override);
    FileWrite(g_slave_status_file_handle, is_connected_str);
    FileWrite(g_slave_status_file_handle, IntegerToString(current_timestamp));
    FileWrite(g_slave_status_file_handle, DoubleToString(current_open_volume, 2));
    FileWrite(g_slave_status_file_handle, IntegerToString(leverage));
    FileWrite(g_slave_status_file_handle, server);

    FileClose(g_slave_status_file_handle);
    g_slave_status_file_handle = INVALID_HANDLE;
    
    g_ea_status_string = status_text_override;
}

//+------------------------------------------------------------------+
//| Mini Dashboard Functions                                         |
//+------------------------------------------------------------------+
void CreateMiniDashText(long chart_id, string name, string text, int x, int y, color clr, int font_size=8, ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER)
{
    ObjectDelete(chart_id, name);
    if(ObjectCreate(chart_id, name, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
        ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, clr);
        ObjectSetInteger(chart_id, name, OBJPROP_FONTSIZE, font_size);
        ObjectSetString(chart_id, name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(chart_id, name, OBJPROP_ANCHOR, anchor);
        ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
    }
}

void Dashboard_Mini_Init()
{
    long chartID = ChartID();
    int y_start = 10;
    int y_step = 15;
    int x_pos = 10;

    CreateMiniDashText(chartID, g_mini_dash_prefix + "Title", "SynPropEA2 Slave v1.00", x_pos, y_start, clrGray);
    y_start += y_step;
    CreateMiniDashText(chartID, g_mini_dash_prefix + "StatusLabel", "Status:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "StatusValue", "Initializing...", x_pos + 60, y_start, clrBlack);
    y_start += y_step;
    CreateMiniDashText(chartID, g_mini_dash_prefix + "LastCmdLabel", "Last Cmd:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "LastCmdValue", "None", x_pos + 60, y_start, clrBlack);
    y_start += y_step;
    
    // Master EA Indicators
    CreateMiniDashText(chartID, g_mini_dash_prefix + "SynergyLabel", "Synergy:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "SynergyValue", "0.00", x_pos + 60, y_start, clrDodgerBlue);
    y_start += y_step;
    CreateMiniDashText(chartID, g_mini_dash_prefix + "ADXLabel", "ADX:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "ADXValue", "0.00", x_pos + 60, y_start, clrOrange);
    y_start += y_step;
    CreateMiniDashText(chartID, g_mini_dash_prefix + "BiasLabel", "Market Bias:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "BiasValue", "0.00", x_pos + 75, y_start, clrMediumOrchid);
    y_start += y_step;
    
    CreateMiniDashText(chartID, g_mini_dash_prefix + "DailyPnLLabel", "Daily PnL:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "DailyPnLValue", "0.00", x_pos + 60, y_start, clrDodgerBlue);
    y_start += y_step;
    CreateMiniDashText(chartID, g_mini_dash_prefix + "BalLabel", "Balance:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "BalValue", "0.00", x_pos + 60, y_start, clrBlack);
    y_start += y_step;
    CreateMiniDashText(chartID, g_mini_dash_prefix + "EqLabel", "Equity:", x_pos, y_start, clrGray);
    CreateMiniDashText(chartID, g_mini_dash_prefix + "EqValue", "0.00", x_pos + 60, y_start, clrBlack);
    ChartRedraw(chartID);
}

void UpdateMiniDashboard()
{
    long chartID = ChartID();
    ObjectSetString(chartID, g_mini_dash_prefix + "StatusValue", OBJPROP_TEXT, g_ea_status_string);
    ObjectSetString(chartID, g_mini_dash_prefix + "LastCmdValue", OBJPROP_TEXT, g_last_cmd_processed_str);
    
    // Update Master EA Indicator Values
    ObjectSetString(chartID, g_mini_dash_prefix + "SynergyValue", OBJPROP_TEXT, DoubleToString(g_master_total_synergy, 2));
    color synergy_color = (g_master_total_synergy > 0) ? clrForestGreen : 
                         (g_master_total_synergy < 0) ? clrFireBrick : clrGray;
    ObjectSetInteger(chartID, g_mini_dash_prefix + "SynergyValue", OBJPROP_COLOR, synergy_color);
    
    bool adx_above_threshold = (g_master_adx_main > g_master_adx_threshold && g_master_adx_main > 0);
    ObjectSetString(chartID, g_mini_dash_prefix + "ADXValue", OBJPROP_TEXT, 
                   StringFormat("%.1f/%.1f", g_master_adx_main, g_master_adx_threshold));
    ObjectSetInteger(chartID, g_mini_dash_prefix + "ADXValue", OBJPROP_COLOR, 
                    adx_above_threshold ? clrForestGreen : clrOrange);
    
    ObjectSetString(chartID, g_mini_dash_prefix + "BiasValue", OBJPROP_TEXT, DoubleToString(g_master_ha_bias, 4));
    color bias_color = (g_master_ha_bias > 0) ? clrDodgerBlue : 
                      (g_master_ha_bias < 0) ? clrCrimson : clrGray;
    ObjectSetInteger(chartID, g_mini_dash_prefix + "BiasValue", OBJPROP_COLOR, bias_color);

    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double daily_pnl = CalculateDailyPnL();  // FIXED: Use corrected calculation function

    ObjectSetString(chartID, g_mini_dash_prefix + "DailyPnLValue", OBJPROP_TEXT, DoubleToString(daily_pnl, 2));
    ObjectSetInteger(chartID, g_mini_dash_prefix + "DailyPnLValue", OBJPROP_COLOR, (daily_pnl >=0 ? clrForestGreen : clrFireBrick));
    ObjectSetString(chartID, g_mini_dash_prefix + "BalValue", OBJPROP_TEXT, DoubleToString(current_balance, 2));
    ObjectSetString(chartID, g_mini_dash_prefix + "EqValue", OBJPROP_TEXT, DoubleToString(current_equity, 2));
    ChartRedraw(chartID);
}

void Dashboard_Mini_Deinit()
{
    ObjectsDeleteAll(ChartID(), g_mini_dash_prefix);
    ChartRedraw(ChartID());
}

//+------------------------------------------------------------------+
//| Read Master Status File                                          |
//+------------------------------------------------------------------+
void ReadMasterStatusFile()
{
    if(InpMasterStatusFile == "") return;

    int file_handle = FileOpen(InpMasterStatusFile, FILE_READ|FILE_CSV|FILE_ANSI|FILE_COMMON, g_csv_delimiter);
    if(file_handle == INVALID_HANDLE)
    {
        static datetime last_error_log_time = 0;
        if(TimeCurrent() - last_error_log_time > 60)
        {
            PrintFormat("ReadMasterStatusFile: Error opening master status file '%s'. Error: %d", InpMasterStatusFile, GetLastError());
            last_error_log_time = TimeCurrent();
        }
        return;
    }

    if(!FileIsEnding(file_handle))
    {
        // Format: TotalSynergyScore,SynergyM5,SynergyM15,SynergyH1,ADXMain,ADXPlus,ADXMinus,ADXThreshold,HABiasOscillator,SessionActive,Timestamp
        string s_total_synergy = FileReadString(file_handle);
        string s_synergy_m5 = FileReadString(file_handle);
        string s_synergy_m15 = FileReadString(file_handle);
        string s_synergy_h1 = FileReadString(file_handle);
        string s_adx_main = FileReadString(file_handle);
        string s_adx_plus = FileReadString(file_handle);
        string s_adx_minus = FileReadString(file_handle);
        string s_adx_threshold = FileReadString(file_handle);
        string s_ha_bias = FileReadString(file_handle);
        string s_session_active = FileReadString(file_handle);
        string s_timestamp = FileReadString(file_handle);

        bool line_properly_ended = FileIsLineEnding(file_handle) || FileIsEnding(file_handle);
        
        if(s_timestamp != "" && line_properly_ended)
        {
            g_master_total_synergy = StringToDouble(s_total_synergy);
            g_master_synergy_m5 = StringToDouble(s_synergy_m5);
            g_master_synergy_m15 = StringToDouble(s_synergy_m15);
            g_master_synergy_h1 = StringToDouble(s_synergy_h1);
            g_master_adx_main = StringToDouble(s_adx_main);
            g_master_adx_plus = StringToDouble(s_adx_plus);
            g_master_adx_minus = StringToDouble(s_adx_minus);
            g_master_adx_threshold = StringToDouble(s_adx_threshold);
            g_master_ha_bias = StringToDouble(s_ha_bias);
            g_master_session_active = (s_session_active == "true");
            g_master_status_timestamp = (datetime)StringToInteger(s_timestamp);
            
            // Check data freshness
            if(TimeCurrent() - g_master_status_timestamp > 120)
            {
                g_master_total_synergy = 0.0;
                g_master_adx_main = 0.0;
                g_master_ha_bias = 0.0;
            }
        }
    }
    FileClose(file_handle);
}

//+------------------------------------------------------------------+
//| Parse Hedge Strategy Information                                 |
//+------------------------------------------------------------------+
ENUM_HEDGE_SCALEOUT_STRATEGY ParseHedgeStrategy(string strategy_info)
{
    if(strategy_info == "") return HEDGE_SCALEOUT_ADAPTIVE; // Default to adaptive
    
    // Extract strategy from format: "STRATEGY=5,REDUCTION=50.0,BE=true,TRIGGER=10.0,COST=700.0"
    int strategy_pos = StringFind(strategy_info, "STRATEGY=");
    if(strategy_pos >= 0)
    {
        string strategy_str = StringSubstr(strategy_info, strategy_pos + 9, 1);
        int strategy_int = (int)StringToInteger(strategy_str);
        
        if(strategy_int >= 0 && strategy_int <= 5)
        {
            // Extract challenge cost if available
            int cost_pos = StringFind(strategy_info, "COST=");
            if(cost_pos >= 0)
            {
                int cost_start = cost_pos + 5;
                int cost_end = StringFind(strategy_info, ",", cost_start);
                if(cost_end == -1) cost_end = StringLen(strategy_info);
                
                if(cost_end > cost_start)
                {
                    string cost_str = StringSubstr(strategy_info, cost_start, cost_end - cost_start);
                    double new_challenge_cost = StringToDouble(cost_str);
                    
                    // Update challenge cost and recalculate thresholds
                    if(new_challenge_cost > 0.0)
                    {
                        UpdateChallengeCostAndThresholds(new_challenge_cost);
                    }
                }
            }
            
            return (ENUM_HEDGE_SCALEOUT_STRATEGY)strategy_int;
        }
    }
    
    return HEDGE_SCALEOUT_ADAPTIVE; // Default fallback
}

//+------------------------------------------------------------------+
//| Calculate Hedge P&L                                             |
//+------------------------------------------------------------------+
double CalculateHedgeUnrealizedPnL(ulong hedge_ticket)
{
    if(!PositionSelectByTicket(hedge_ticket)) return 0.0;
    
    double unrealized_pnl = PositionGetDouble(POSITION_PROFIT);
    return unrealized_pnl;
}

//+------------------------------------------------------------------+
//| Execute Adaptive Hedge Response                                  |
//+------------------------------------------------------------------+
bool ExecuteAdaptiveHedgeResponse(ulong master_ticket, ulong hedge_ticket, double master_scaled_volume,
                                 double master_scaleout_price, double master_tp_distance_pct)
{
    double hedge_pnl = CalculateHedgeUnrealizedPnL(hedge_ticket);
    double hedge_volume = PositionGetDouble(POSITION_VOLUME);
    double hedge_entry = PositionGetDouble(POSITION_PRICE_OPEN);
    
    // Calculate hedge loss percentage
    double hedge_loss_percentage = 0.0;
    if(hedge_pnl < 0.0 && g_challenge_cost > 0.0)
    {
        hedge_loss_percentage = (MathAbs(hedge_pnl) / g_challenge_cost) * 100.0;
    }
    
    PrintFormat("ExecuteAdaptiveHedgeResponse: Master scaled out %.2f lots at %.1f%% TP. Hedge PnL: $%.2f (%.1f%% of challenge cost $%.2f)", 
               master_scaled_volume, master_tp_distance_pct, hedge_pnl, hedge_loss_percentage, g_challenge_cost);
    PrintFormat("Adaptive Thresholds: Low=%.1f%% ($%.2f), High=%.1f%% ($%.2f)", 
               InpHedgeLossThresholdLow, g_hedge_loss_threshold_low_dollars,
               InpHedgeLossThresholdHigh, g_hedge_loss_threshold_high_dollars);
    
    // Decision logic based on hedge P&L
    if(hedge_pnl >= -g_hedge_loss_threshold_low_dollars) // Small loss or profit
    {
        // Strategy: Move to breakeven
        PrintFormat("Adaptive Response: Small loss ($%.2f = %.1f%%), applying breakeven protection", hedge_pnl, hedge_loss_percentage);
        return ApplyHedgeBreakeven(hedge_ticket);
    }
    else if(hedge_pnl >= -g_hedge_loss_threshold_high_dollars) // Medium loss
    {
        // Strategy: Reduce hedge by 25%
        PrintFormat("Adaptive Response: Medium loss ($%.2f = %.1f%%), reducing hedge by 25%%", hedge_pnl, hedge_loss_percentage);
        double reduction_volume = hedge_volume * 0.25;
        return ApplyHedgeReduction(hedge_ticket, reduction_volume, "Adaptive_25pct");
    }
    else // High loss
    {
        // Strategy: Reduce hedge by 50%
        PrintFormat("Adaptive Response: High loss ($%.2f = %.1f%%), reducing hedge by 50%%", hedge_pnl, hedge_loss_percentage);
        double reduction_volume = hedge_volume * 0.50;
        return ApplyHedgeReduction(hedge_ticket, reduction_volume, "Adaptive_50pct");
    }
}

//+------------------------------------------------------------------+
//| Apply Hedge Breakeven                                           |
//+------------------------------------------------------------------+
bool ApplyHedgeBreakeven(ulong hedge_ticket)
{
    if(!PositionSelectByTicket(hedge_ticket)) return false;
    
    double hedge_entry = PositionGetDouble(POSITION_PRICE_OPEN);
    double current_tp = PositionGetDouble(POSITION_TP);
    
    // Add small buffer to account for spread
    int spread_points = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    double spread = spread_points * g_point_value;
    ENUM_POSITION_TYPE position_type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
    
    double breakeven_sl = hedge_entry;
    if(position_type == POSITION_TYPE_BUY)
    {
        breakeven_sl = hedge_entry + spread; // BUY: SL slightly above entry
    }
    else
    {
        breakeven_sl = hedge_entry - spread; // SELL: SL slightly below entry
    }
    
    bool result = trade.PositionModify(hedge_ticket, breakeven_sl, current_tp);
    
    if(result)
    {
        PrintFormat("✅ ApplyHedgeBreakeven: Hedge #%d moved to breakeven (SL: %.5f)", hedge_ticket, breakeven_sl);
    }
    else
    {
        PrintFormat("❌ ApplyHedgeBreakeven: Failed to move hedge #%d to breakeven", hedge_ticket);
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Apply Hedge Reduction                                           |
//+------------------------------------------------------------------+
bool ApplyHedgeReduction(ulong hedge_ticket, double reduction_volume, string reason)
{
    if(!PositionSelectByTicket(hedge_ticket)) return false;
    
    double current_volume = PositionGetDouble(POSITION_VOLUME);
    double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
    double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
    
    // Validate and normalize reduction volume
    double close_volume = MathMin(reduction_volume, current_volume);
    close_volume = MathMax(close_volume, min_volume);
    
    if(volume_step > 0)
    {
        close_volume = MathRound(close_volume / volume_step) * volume_step;
    }
    
    // Don't close if remaining volume would be too small
    double remaining_volume = current_volume - close_volume;
    if(remaining_volume > 0 && remaining_volume < min_volume)
    {
        close_volume = current_volume; // Close entire position
    }
    
    PrintFormat("ApplyHedgeReduction: Attempting to close %.2f lots from hedge #%d (%.2f total). Reason: %s", 
               close_volume, hedge_ticket, current_volume, reason);
    
    bool result = trade.PositionClosePartial(hedge_ticket, close_volume);
    
    if(result)
    {
        PrintFormat("✅ ApplyHedgeReduction: Successfully closed %.2f lots from hedge #%d", close_volume, hedge_ticket);
        
        // If there's remaining volume, apply breakeven to it
        if(remaining_volume >= min_volume)
        {
            Sleep(500); // Brief pause to ensure partial close is processed
            ApplyHedgeBreakeven(hedge_ticket);
        }
    }
    else
    {
        PrintFormat("❌ ApplyHedgeReduction: Failed to reduce hedge #%d. Error: %d", hedge_ticket, GetLastError());
    }
    
    return result;
}

//+------------------------------------------------------------------+
//| Execute Hedge Scale-Out Response                                 |
//+------------------------------------------------------------------+
bool ExecuteHedgeScaleoutResponse(ulong master_ticket, double master_scaled_volume, 
                                 double master_scaleout_price, double master_tp_distance_pct, 
                                 string strategy_info)
{
    if(!InpEnableHedgeResponse)
    {
        PrintFormat("ExecuteHedgeScaleoutResponse: Hedge response disabled. Master ticket %d scale-out ignored.", master_ticket);
        return true; // Not a failure, just disabled
    }
    
    // Find corresponding hedge position
    ulong hedge_ticket = FindSlavePositionByMasterTicket(master_ticket);
    if(hedge_ticket == 0)
    {
        PrintFormat("ExecuteHedgeScaleoutResponse: No hedge position found for master ticket %d", master_ticket);
        return false;
    }
    
    ENUM_HEDGE_SCALEOUT_STRATEGY strategy = ParseHedgeStrategy(strategy_info);
    
    PrintFormat("🎯 HEDGE SCALE-OUT RESPONSE: Master #%d scaled out %.2f lots at %.1f%% TP (Price: %.5f)", 
               master_ticket, master_scaled_volume, master_tp_distance_pct, master_scaleout_price);
    PrintFormat("Hedge Strategy: %s, Hedge Ticket: #%d", 
               EnumToString(strategy), hedge_ticket);
    
    switch(strategy)
    {
        case HEDGE_SCALEOUT_NONE:
            PrintFormat("Hedge Response: NONE - Maintaining full hedge position");
            return true;
            
        case HEDGE_SCALEOUT_BREAKEVEN:
            PrintFormat("Hedge Response: BREAKEVEN - Moving hedge to breakeven");
            return ApplyHedgeBreakeven(hedge_ticket);
            
        case HEDGE_SCALEOUT_REDUCE:
            {
                double reduction_volume = PositionGetDouble(POSITION_VOLUME) * (InpHedgeReductionPercentage / 100.0);
                PrintFormat("Hedge Response: REDUCE - Reducing hedge by %.1f%%", InpHedgeReductionPercentage);
                return ApplyHedgeReduction(hedge_ticket, reduction_volume, "Strategy_Reduce");
            }
            
        case HEDGE_SCALEOUT_CLOSE_PARTIAL:
            {
                // Mirror master's scale-out percentage
                double hedge_volume = PositionGetDouble(POSITION_VOLUME);
                double master_scaleout_pct = master_scaled_volume / hedge_volume * 100.0; // Estimate percentage
                double reduction_volume = hedge_volume * (master_scaleout_pct / 100.0);
                PrintFormat("Hedge Response: CLOSE_PARTIAL - Mirroring master's %.1f%% scale-out", master_scaleout_pct);
                return ApplyHedgeReduction(hedge_ticket, reduction_volume, "Mirror_Master");
            }
            
        case HEDGE_SCALEOUT_INVERSE:
            {
                // Check if hedge is profitable for inverse scale-out
                double hedge_pnl = CalculateHedgeUnrealizedPnL(hedge_ticket);
                if(hedge_pnl > 0)
                {
                    double reduction_volume = PositionGetDouble(POSITION_VOLUME) * 0.50; // 50% when profitable
                    PrintFormat("Hedge Response: INVERSE - Hedge profitable ($%.2f), scaling out 50%%", hedge_pnl);
                    return ApplyHedgeReduction(hedge_ticket, reduction_volume, "Inverse_Profit");
                }
                else
                {
                    PrintFormat("Hedge Response: INVERSE - Hedge not profitable ($%.2f), maintaining position", hedge_pnl);
                    return true;
                }
            }
            
        case HEDGE_SCALEOUT_ADAPTIVE:
        default:
            PrintFormat("Hedge Response: ADAPTIVE - Analyzing hedge P&L for optimal response");
            return ExecuteAdaptiveHedgeResponse(master_ticket, hedge_ticket, master_scaled_volume, 
                                              master_scaleout_price, master_tp_distance_pct);
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Update Challenge Cost and Calculate Thresholds                  |
//+------------------------------------------------------------------+
void UpdateChallengeCostAndThresholds(double new_challenge_cost)
{
    if(new_challenge_cost > 0.0)
    {
        g_challenge_cost = new_challenge_cost;
    }
    else
    {
        g_challenge_cost = InpChallengeCost_HedgeContext; // Use input as fallback
    }
    
    // Calculate dollar thresholds from percentages
    g_hedge_loss_threshold_low_dollars = g_challenge_cost * (InpHedgeLossThresholdLow / 100.0);
    g_hedge_loss_threshold_high_dollars = g_challenge_cost * (InpHedgeLossThresholdHigh / 100.0);
    
    PrintFormat("UpdateChallengeCostAndThresholds: Challenge Cost: $%.2f, Low Threshold: $%.2f (%.1f%%), High Threshold: $%.2f (%.1f%%)",
               g_challenge_cost, g_hedge_loss_threshold_low_dollars, InpHedgeLossThresholdLow, 
               g_hedge_loss_threshold_high_dollars, InpHedgeLossThresholdHigh);
}

//+------------------------------------------------------------------+
//| Calculate Current Hedge P&L and Percentage                      |
//+------------------------------------------------------------------+
void UpdateCurrentHedgePnL()
{
    g_current_hedge_pnl = 0.0;
    g_hedge_loss_percentage = 0.0;
    
    int total_positions = PositionsTotal();
    for(int i = 0; i < total_positions; i++)
    {
        ulong ticket = PositionGetTicket(i);
        if(PositionSelectByTicket(ticket))
        {
            if(PositionGetInteger(POSITION_MAGIC) == InpMagicNumber_Slave &&
               PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                g_current_hedge_pnl += PositionGetDouble(POSITION_PROFIT);
                break; // Assuming one hedge position
            }
        }
    }
    
    // Calculate percentage loss (only if negative)
    if(g_current_hedge_pnl < 0.0 && g_challenge_cost > 0.0)
    {
        g_hedge_loss_percentage = (MathAbs(g_current_hedge_pnl) / g_challenge_cost) * 100.0;
    }
    else if(g_current_hedge_pnl >= 0.0)
    {
        g_hedge_loss_percentage = 0.0; // No loss if profitable
    }
}

//+------------------------------------------------------------------+
//| Cumulative PnL Tracking System (COMPREHENSIVE IMPLEMENTATION)   |
//+------------------------------------------------------------------+

// Initialize cumulative tracking system
void InitializeCumulativeTracking()
{
    if(!InpEnableCumulativeTracking) return;
    
    // Initialize cumulative history structure
    g_cumulative_history.period_start = TimeCurrent();
    g_cumulative_history.equity_start = AccountInfoDouble(ACCOUNT_EQUITY);
    g_cumulative_history.balance_start = AccountInfoDouble(ACCOUNT_BALANCE);
    g_cumulative_history.total_flows = 0.0;           // Prop trading: typically no deposits/withdrawals
    g_cumulative_history.total_realized_pnl = 0.0;
    g_cumulative_history.total_commissions = 0.0;
    g_cumulative_history.total_financing = 0.0;
    g_cumulative_history.peak_equity = g_cumulative_history.equity_start;
    g_cumulative_history.max_drawdown_amount = 0.0;
    g_cumulative_history.max_drawdown_percent = 0.0;
    g_cumulative_history.max_drawdown_date = 0;
    g_cumulative_history.trading_days_count = 0;
    
    // Initialize history arrays
    ArrayResize(g_daily_pnl_array, InpMaxHistoryDays);
    ArrayResize(g_daily_dates_array, InpMaxHistoryDays);
    g_cumulative_history_size = 0;
    
    g_cumulative_tracking_initialized = true;
    
    PrintFormat("📊 CUMULATIVE TRACKING INITIALIZED: Start Equity=%.2f, Start Balance=%.2f", 
                g_cumulative_history.equity_start, g_cumulative_history.balance_start);
}

// Calculate cumulative PnL using equity-based approach (per user's formula)
double CalculateCumulativePnL()
{
    if(!g_cumulative_tracking_initialized) return 0.0;
    
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    
    // User's Master Formula: CumulativePnL = (Equity_End - Equity_Start) - Sum(Flows)
    double cumulative_pnl = (current_equity - g_cumulative_history.equity_start) - g_cumulative_history.total_flows;
    
    return cumulative_pnl;
}

// Calculate cumulative realized PnL component
double CalculateCumulativeRealizedPnL()
{
    if(!g_cumulative_tracking_initialized) return 0.0;
    
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    
    // Realized = Balance change since start
    return current_balance - g_cumulative_history.balance_start;
}

// Calculate cumulative unrealized PnL component
double CalculateCumulativeUnrealizedPnL()
{
    if(!g_cumulative_tracking_initialized) return 0.0;
    
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double start_equity = g_cumulative_history.equity_start;
    double start_balance = g_cumulative_history.balance_start;
    
    // Current unrealized = (Current Equity - Current Balance)
    // Starting unrealized = (Starting Equity - Starting Balance)  
    // Cumulative unrealized change = Current unrealized - Starting unrealized
    return (current_equity - current_balance) - (start_equity - start_balance);
}

// Update cumulative tracking with daily data
void UpdateCumulativeTracking(double daily_pnl)
{
    if(!InpEnableCumulativeTracking || !g_cumulative_tracking_initialized) return;
    
    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    datetime current_time = TimeCurrent();
    
    // Add daily PnL to history arrays
    if(g_cumulative_history_size < InpMaxHistoryDays)
    {
        g_daily_pnl_array[g_cumulative_history_size] = daily_pnl;
        g_daily_dates_array[g_cumulative_history_size] = current_time;
        g_cumulative_history_size++;
    }
    else
    {
        // Shift arrays left and add new value (rolling window)
        for(int i = 0; i < InpMaxHistoryDays - 1; i++)
        {
            g_daily_pnl_array[i] = g_daily_pnl_array[i + 1];
            g_daily_dates_array[i] = g_daily_dates_array[i + 1];
        }
        g_daily_pnl_array[InpMaxHistoryDays - 1] = daily_pnl;
        g_daily_dates_array[InpMaxHistoryDays - 1] = current_time;
    }
    
    // Update peak equity tracking
    if(current_equity > g_cumulative_history.peak_equity)
    {
        g_cumulative_history.peak_equity = current_equity;
    }
    
    // Update drawdown tracking
    if(InpTrackDrawdownDetails)
    {
        double current_drawdown_amount = g_cumulative_history.peak_equity - current_equity;
        double current_drawdown_percent = (g_cumulative_history.peak_equity > 0) ? 
            (current_drawdown_amount / g_cumulative_history.peak_equity) * 100.0 : 0.0;
            
        if(current_drawdown_amount > g_cumulative_history.max_drawdown_amount)
        {
            g_cumulative_history.max_drawdown_amount = current_drawdown_amount;
            g_cumulative_history.max_drawdown_percent = current_drawdown_percent;
            g_cumulative_history.max_drawdown_date = current_time;
        }
    }
    
    // Update trading days count
    g_cumulative_history.trading_days_count++;
}

// Comprehensive cumulative PnL structure
struct ComprehensiveCumulativePnL
{
    double total_cumulative_pnl;        // Total cumulative P&L (equity-based)
    double cumulative_realized_pnl;     // Cumulative realized P&L component
    double cumulative_unrealized_pnl;   // Cumulative unrealized P&L component
    double period_return_percent;       // Period return as percentage
    double annualized_return_percent;   // Annualized return (estimated)
    double current_equity;              // Current account equity
    double starting_equity;             // Starting period equity
    double peak_equity;                 // Peak equity reached
    double current_drawdown_amount;     // Current drawdown from peak
    double current_drawdown_percent;    // Current drawdown as percentage
    double max_drawdown_amount;         // Maximum drawdown experienced
    double max_drawdown_percent;        // Maximum drawdown as percentage
    datetime period_start;              // Period start date
    datetime current_time;              // Current timestamp
    int trading_days;                   // Number of trading days
    double total_flows;                 // Total cash flows (deposits - withdrawals)
};

ComprehensiveCumulativePnL GetComprehensiveCumulativePnL()
{
    ComprehensiveCumulativePnL result;
    
    if(!g_cumulative_tracking_initialized)
    {
        // Return zero-initialized structure if not initialized
        ZeroMemory(result);
        return result;
    }
    
    // Core calculations using user's mathematical reference
    result.total_cumulative_pnl = CalculateCumulativePnL();
    result.cumulative_realized_pnl = CalculateCumulativeRealizedPnL();
    result.cumulative_unrealized_pnl = CalculateCumulativeUnrealizedPnL();
    
    // Account state information
    result.current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    result.starting_equity = g_cumulative_history.equity_start;
    result.peak_equity = g_cumulative_history.peak_equity;
    
    // Return calculations
    result.period_return_percent = (result.starting_equity > 0) ? 
        (result.total_cumulative_pnl / result.starting_equity) * 100.0 : 0.0;
    
    // Annualized return (simple approximation - 252 trading days per year)
    result.annualized_return_percent = 0.0;
    if(g_cumulative_history.trading_days_count > 0 && result.starting_equity > 0)
    {
        double period_return_ratio = 1.0 + (result.total_cumulative_pnl / result.starting_equity);
        double days_per_year = 252.0;
        double period_fraction = g_cumulative_history.trading_days_count / days_per_year;
        
        if(period_fraction > 0 && period_return_ratio > 0)
        {
            result.annualized_return_percent = (MathPow(period_return_ratio, 1.0 / period_fraction) - 1.0) * 100.0;
        }
    }
    
    // Drawdown calculations
    result.current_drawdown_amount = result.peak_equity - result.current_equity;
    result.current_drawdown_percent = (result.peak_equity > 0) ? 
        (result.current_drawdown_amount / result.peak_equity) * 100.0 : 0.0;
    result.max_drawdown_amount = g_cumulative_history.max_drawdown_amount;
    result.max_drawdown_percent = g_cumulative_history.max_drawdown_percent;
    
    // Timing information
    result.period_start = g_cumulative_history.period_start;
    result.current_time = TimeCurrent();
    result.trading_days = g_cumulative_history.trading_days_count;
    result.total_flows = g_cumulative_history.total_flows;
    
    return result;
}

void LogComprehensiveCumulativePnL()
{
    if(!InpEnableCumulativeLogging || !g_cumulative_tracking_initialized) return;
    
    static datetime last_log_time = 0;
    if(TimeCurrent() - last_log_time < 600) return; // Log every 10 minutes max
    
    ComprehensiveCumulativePnL cum = GetComprehensiveCumulativePnL();
    
    PrintFormat("💰 COMPREHENSIVE CUMULATIVE PnL REPORT:");
    PrintFormat("   📊 Total Cumulative P&L: %.2f (%.2f%%)", cum.total_cumulative_pnl, cum.period_return_percent);
    PrintFormat("   📈 Components: Realized=%.2f + Unrealized=%.2f", cum.cumulative_realized_pnl, cum.cumulative_unrealized_pnl);
    PrintFormat("   🎯 Annualized Return: %.2f%% (estimated)", cum.annualized_return_percent);
    PrintFormat("   📉 Current Drawdown: %.2f (%.2f%% from peak)", cum.current_drawdown_amount, cum.current_drawdown_percent);
    PrintFormat("   ⬇️  Max Drawdown: %.2f (%.2f%% max reached)", cum.max_drawdown_amount, cum.max_drawdown_percent);
    PrintFormat("   💵 Equity Journey: %.2f -> %.2f (Peak: %.2f)", cum.starting_equity, cum.current_equity, cum.peak_equity);
    PrintFormat("   📅 Period: %d trading days since %s", cum.trading_days, TimeToString(cum.period_start, TIME_DATE));
    
    // Validation check (following user's mathematical reference)
    double component_sum = cum.cumulative_realized_pnl + cum.cumulative_unrealized_pnl;
    double validation_diff = MathAbs(cum.total_cumulative_pnl - component_sum);
    if(validation_diff > 0.01)
    {
        PrintFormat("⚠️  CUMULATIVE VALIDATION WARNING: Component sum (%.2f) != Total (%.2f), Diff: %.2f", 
                   component_sum, cum.total_cumulative_pnl, validation_diff);
    }
    else
    {
        PrintFormat("✅ CUMULATIVE VALIDATION PASSED: Components sum correctly");
    }
    
    last_log_time = TimeCurrent();
}

//+------------------------------------------------------------------+
//| EA2 STATUS REPORTING SYSTEM (FOR EA1 SAFETY VERIFICATION)       |
//+------------------------------------------------------------------+

// Initialize EA2 status reporting system
void InitializeEA2StatusReporting()
{
    g_last_status_update_time = 0;
    g_ea2_is_monitoring = false;
    g_ea2_is_ready = false;
    g_status_update_counter = 0;
    g_ea2_current_status = "Initializing";
    
    if(InpEnableDetailedStatusLogs)
    {
        PrintFormat("🔄 EA2 STATUS REPORTING INITIALIZED");
        PrintFormat("   📊 Update Interval: %d seconds", InpStatusUpdateIntervalSec);
        PrintFormat("   📡 Reporting Enabled: %s", InpEnableStatusReporting ? "YES" : "NO");
    }
}

// Get current EA2 status information
EA2StatusInfo GetEA2StatusInfo()
{
    EA2StatusInfo status;
    
    status.is_monitoring = g_ea2_is_monitoring;
    status.is_ready = g_ea2_is_ready;
    status.is_connected = true; // EA2 is running if this function is called
    status.status_message = g_ea2_current_status;
    status.last_update_time = g_last_status_update_time;
    status.update_counter = g_status_update_counter;
    status.balance = AccountInfoDouble(ACCOUNT_BALANCE);
    status.equity = AccountInfoDouble(ACCOUNT_EQUITY);
    status.server = AccountInfoString(ACCOUNT_SERVER);
    status.leverage = (int)AccountInfoInteger(ACCOUNT_LEVERAGE);
    
    return status;
}

// Update EA2 status based on current state
void UpdateEA2Status()
{
    // Determine current status based on EA2 state
    if(!g_ea2_is_monitoring)
    {
        g_ea2_current_status = "Starting Up";
        g_ea2_is_ready = false;
    }
    else if(g_ea2_is_monitoring && !g_ea2_is_ready)
    {
        g_ea2_current_status = "Monitoring - Getting Ready";
        g_ea2_is_ready = true; // Set ready once monitoring starts
    }
    else
    {
        // Check if we have recent command file activity
        bool has_recent_activity = (TimeCurrent() - g_last_status_update_time) < 60;
        
        if(has_recent_activity)
        {
            g_ea2_current_status = "Ready - Monitoring Commands";
        }
        else
        {
            g_ea2_current_status = "Ready - Standby Mode";
        }
    }
}

// Send status update to EA1 (via status file)
void SendStatusUpdateToEA1()
{
    if(!InpEnableStatusReporting) return;
    
    datetime current_time = TimeCurrent();
    
    // Check if it's time for status update
    if(g_last_status_update_time > 0 && 
       (current_time - g_last_status_update_time) < InpStatusUpdateIntervalSec)
    {
        return; // Not time yet
    }
    
    // Update status before sending
    UpdateEA2Status();
    
    EA2StatusInfo status = GetEA2StatusInfo();
    
    // Enhanced status message with more details for EA1 verification
    string enhanced_status = StringFormat("%s|Monitoring:%s|Ready:%s|Updates:%d|Server:%s",
                                         status.status_message,
                                         status.is_monitoring ? "YES" : "NO",
                                         status.is_ready ? "YES" : "NO",
                                         status.update_counter,
                                         status.server);
    
    // Write to status file (this updates the existing WriteSlaveStatusFile function)
    WriteSlaveStatusFile(enhanced_status);
    
    g_last_status_update_time = current_time;
    g_status_update_counter++;
    
    if(InpEnableDetailedStatusLogs)
    {
        static int log_counter = 0;
        log_counter++;
        
        // Log every 5th update to avoid spam
        if(log_counter % 5 == 1)
        {
            PrintFormat("📡 EA2 STATUS UPDATE #%d sent to EA1:", g_status_update_counter);
            PrintFormat("   🔄 Status: %s", status.status_message);
            PrintFormat("   👁️  Monitoring: %s", status.is_monitoring ? "YES" : "NO");
            PrintFormat("   ✅ Ready: %s", status.is_ready ? "YES" : "NO");
            PrintFormat("   💰 Balance: %.2f, Equity: %.2f", status.balance, status.equity);
            PrintFormat("   🌐 Server: %s, Leverage: %d", status.server, status.leverage);
        }
    }
}

// Set EA2 monitoring status (called when EA2 starts monitoring commands)
void SetEA2MonitoringStatus(bool is_monitoring)
{
    bool status_changed = (g_ea2_is_monitoring != is_monitoring);
    g_ea2_is_monitoring = is_monitoring;
    
    if(status_changed)
    {
        if(is_monitoring)
        {
            PrintFormat("✅ EA2 MONITORING STARTED - Now ready to receive commands from EA1");
            g_ea2_current_status = "Monitoring - Ready";
            g_ea2_is_ready = true;
        }
        else
        {
            PrintFormat("⚠️  EA2 MONITORING STOPPED");
            g_ea2_current_status = "Stopped";
            g_ea2_is_ready = false;
        }
        
        // Send immediate status update when monitoring status changes
        SendStatusUpdateToEA1();
    }
}

// Log comprehensive EA2 status for debugging
void LogEA2StatusForDebugging()
{
    if(!InpEnableDetailedStatusLogs) return;
    
    static datetime last_debug_log = 0;
    if(TimeCurrent() - last_debug_log < 120) return; // Log every 2 minutes max
    
    EA2StatusInfo status = GetEA2StatusInfo();
    
    PrintFormat("🔍 EA2 STATUS DEBUG REPORT:");
    PrintFormat("   📊 Monitoring: %s", status.is_monitoring ? "YES" : "NO");
    PrintFormat("   ✅ Ready: %s", status.is_ready ? "YES" : "NO");
    PrintFormat("   🔌 Connected: %s", status.is_connected ? "YES" : "NO");
    PrintFormat("   📝 Status: %s", status.status_message);
    PrintFormat("   📈 Updates Sent: %d", status.update_counter);
    PrintFormat("   ⏰ Last Update: %s", TimeToString(status.last_update_time));
    PrintFormat("   💰 Account: Balance=%.2f, Equity=%.2f", status.balance, status.equity);
    PrintFormat("   🌐 Server: %s, Leverage: %d", status.server, status.leverage);
    
    last_debug_log = TimeCurrent();
}

// Force immediate status update (for critical events)
void ForceStatusUpdateToEA1(string reason)
{
    if(!InpEnableStatusReporting) return;
    
    UpdateEA2Status();
    g_ea2_current_status = StringFormat("%s - %s", g_ea2_current_status, reason);
    
    SendStatusUpdateToEA1();
    
    if(InpEnableDetailedStatusLogs)
    {
        PrintFormat("🚨 FORCED STATUS UPDATE: %s", reason);
    }
}

// Enhanced WriteSlaveStatusFile function for EA1 safety verification
void WriteSlaveStatusFile(string enhanced_status_message)
{
    // Use the existing UpdateAndWriteSlaveStatusFile but with enhanced status
    UpdateAndWriteSlaveStatusFile(true, enhanced_status_message);
}   