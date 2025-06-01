//+------------------------------------------------------------------+
//| SynPropEA1_Dashboard.mqh                                         |
//| Fresh, Clean Dashboard Implementation                            |
//+------------------------------------------------------------------+

#property strict

//+------------------------------------------------------------------+
//| Dashboard Layout Constants                                       |
//+------------------------------------------------------------------+
#define DASH_PREFIX          "SynPropDash_"
#define DASH_START_X         10
#define DASH_START_Y         25

// Column widths
#define COL_LABEL_WIDTH      160
#define COL_VALUE_WIDTH      180
#define COL_PROP_WIDTH       100
#define COL_SLAVE_WIDTH      100
#define COL_REMARKS_WIDTH    110

// Row heights
#define ROW_HEIGHT           18
#define HEADER_HEIGHT        20
#define SECTION_SPACING      8
#define TEXT_PADDING         5

//+------------------------------------------------------------------+
//| Dashboard Colors                                                 |
//+------------------------------------------------------------------+
#define COLOR_BG_HEADER      C'51,51,102'      // Dark blue header
#define COLOR_BG_INFO        C'230,240,250'    // Light blue info
#define COLOR_BG_DATA        C'245,245,245'    // Light gray data
#define COLOR_BG_SUCCESS     C'220,255,220'    // Light green
#define COLOR_BG_WARNING     C'255,255,220'    // Light yellow
#define COLOR_BG_DANGER      C'255,220,220'    // Light red

#define COLOR_TEXT_HEADER    clrWhite
#define COLOR_TEXT_NORMAL    clrBlack
#define COLOR_TEXT_SUCCESS   clrGreen
#define COLOR_TEXT_DANGER    clrRed
#define COLOR_TEXT_WARNING   clrOrange

//+------------------------------------------------------------------+
//| Object Name Constants                                            |
//+------------------------------------------------------------------+
// Top Section
#define OBJ_DATETIME         DASH_PREFIX + "DateTime"
#define OBJ_STATUS           DASH_PREFIX + "Status"

// Live Trading Section
#define OBJ_LT_HEADER        DASH_PREFIX + "LT_Header"
#define OBJ_LT_VOLUME_LABEL  DASH_PREFIX + "LT_VolumeLabel"
#define OBJ_LT_VOLUME_PROP   DASH_PREFIX + "LT_VolumeProp"
#define OBJ_LT_VOLUME_SLAVE  DASH_PREFIX + "LT_VolumeSlave"
#define OBJ_LT_PNL_LABEL     DASH_PREFIX + "LT_PnLLabel"
#define OBJ_LT_PNL_PROP      DASH_PREFIX + "LT_PnLProp"
#define OBJ_LT_PNL_SLAVE     DASH_PREFIX + "LT_PnLSlave"

// Account Info Section
#define OBJ_AI_HEADER        DASH_PREFIX + "AI_Header"
#define OBJ_AI_ACC_LABEL     DASH_PREFIX + "AI_AccLabel"
#define OBJ_AI_ACC_PROP      DASH_PREFIX + "AI_AccProp"
#define OBJ_AI_ACC_SLAVE     DASH_PREFIX + "AI_AccSlave"
#define OBJ_AI_BAL_LABEL     DASH_PREFIX + "AI_BalLabel"
#define OBJ_AI_BAL_PROP      DASH_PREFIX + "AI_BalProp"
#define OBJ_AI_BAL_SLAVE     DASH_PREFIX + "AI_BalSlave"
#define OBJ_AI_EQ_LABEL      DASH_PREFIX + "AI_EqLabel"
#define OBJ_AI_EQ_PROP       DASH_PREFIX + "AI_EqProp"
#define OBJ_AI_EQ_SLAVE      DASH_PREFIX + "AI_EqSlave"
#define OBJ_AI_CONN_LABEL    DASH_PREFIX + "AI_ConnLabel"
#define OBJ_AI_CONN_STATUS   DASH_PREFIX + "AI_ConnStatus"

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+
void CreateBackground(string name, int x, int y, int width, int height, color bg_color)
{
    ObjectDelete(ChartID(), name);
    if(ObjectCreate(ChartID(), name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(ChartID(), name, OBJPROP_XSIZE, width);
        ObjectSetInteger(ChartID(), name, OBJPROP_YSIZE, height);
        ObjectSetInteger(ChartID(), name, OBJPROP_BGCOLOR, bg_color);
        ObjectSetInteger(ChartID(), name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(ChartID(), name, OBJPROP_BACK, true);
    }
}

void CreateLabel(string name, string text, int x, int y, color text_color, 
                 int font_size = 9, ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER)
{
    ObjectDelete(ChartID(), name);
    if(ObjectCreate(ChartID(), name, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetString(ChartID(), name, OBJPROP_TEXT, text);
        ObjectSetInteger(ChartID(), name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(ChartID(), name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(ChartID(), name, OBJPROP_COLOR, text_color);
        ObjectSetInteger(ChartID(), name, OBJPROP_FONTSIZE, font_size);
        ObjectSetString(ChartID(), name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(ChartID(), name, OBJPROP_ANCHOR, anchor);
    }
}

//+------------------------------------------------------------------+
//| Dashboard Section Creation Functions                             |
//+------------------------------------------------------------------+
int CreateTopSection(int start_y)
{
    int y = start_y;
    int section_width = COL_LABEL_WIDTH + COL_VALUE_WIDTH;
    
    // DateTime (right-aligned)
    int datetime_x = int(ChartGetInteger(ChartID(), CHART_WIDTH_IN_PIXELS) - 200);
    CreateLabel(OBJ_DATETIME, TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS), 
                datetime_x, y - ROW_HEIGHT, COLOR_TEXT_NORMAL, 8, ANCHOR_RIGHT_UPPER);
    
    // Status row
    CreateBackground(DASH_PREFIX + "StatusBg", DASH_START_X, y, section_width, ROW_HEIGHT, COLOR_BG_WARNING);
    CreateLabel(DASH_PREFIX + "StatusLabel", "Status:", DASH_START_X + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    CreateLabel(OBJ_STATUS, "Initializing...", DASH_START_X + COL_LABEL_WIDTH + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    y += ROW_HEIGHT;
    
    return y + SECTION_SPACING;
}

int CreateLiveTradingSection(int start_y)
{
    int y = start_y;
    int section_width = COL_LABEL_WIDTH + COL_PROP_WIDTH + COL_SLAVE_WIDTH + COL_REMARKS_WIDTH + 3 * TEXT_PADDING;
    
    // Header
    CreateBackground(DASH_PREFIX + "LT_HeaderBg", DASH_START_X, y, section_width, HEADER_HEIGHT, COLOR_BG_HEADER);
    CreateLabel(OBJ_LT_HEADER, "Live Trading Information", DASH_START_X + section_width/2, y + HEADER_HEIGHT/2, COLOR_TEXT_HEADER, 10, ANCHOR_CENTER);
    y += HEADER_HEIGHT;
    
    // Sub-header
    int x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "LT_SubHeaderBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_INFO);
    CreateLabel(DASH_PREFIX + "LT_SubLabel", "", x + COL_LABEL_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateLabel(DASH_PREFIX + "LT_SubProp", "Master (Prop)", x + COL_PROP_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_PROP_WIDTH + TEXT_PADDING;
    CreateLabel(DASH_PREFIX + "LT_SubSlave", "Slave (Hedge)", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_SLAVE_WIDTH + TEXT_PADDING;
    CreateLabel(DASH_PREFIX + "LT_SubRemarks", "Status", x + COL_REMARKS_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    // Volume row
    x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "LT_VolumeBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_DATA);
    CreateLabel(OBJ_LT_VOLUME_LABEL, "Volume:", x + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_LT_VOLUME_PROP, "0.00", x + COL_PROP_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_PROP_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_LT_VOLUME_SLAVE, "0.00", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    // Daily PnL row
    x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "LT_PnLBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_DATA);
    CreateLabel(OBJ_LT_PNL_LABEL, "Daily PnL:", x + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_LT_PNL_PROP, "0.00", x + COL_PROP_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_PROP_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_LT_PNL_SLAVE, "0.00", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    return y + SECTION_SPACING;
}

int CreateAccountInfoSection(int start_y)
{
    int y = start_y;
    int section_width = COL_LABEL_WIDTH + COL_PROP_WIDTH + COL_SLAVE_WIDTH + COL_REMARKS_WIDTH + 3 * TEXT_PADDING;
    
    // Header
    CreateBackground(DASH_PREFIX + "AI_HeaderBg", DASH_START_X, y, section_width, HEADER_HEIGHT, COLOR_BG_HEADER);
    CreateLabel(OBJ_AI_HEADER, "Account Information", DASH_START_X + section_width/2, y + HEADER_HEIGHT/2, COLOR_TEXT_HEADER, 10, ANCHOR_CENTER);
    y += HEADER_HEIGHT;
    
    // Sub-header
    int x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "AI_SubHeaderBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_INFO);
    CreateLabel(DASH_PREFIX + "AI_SubLabel", "", x + COL_LABEL_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateLabel(DASH_PREFIX + "AI_SubProp", "Master Account", x + COL_PROP_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_PROP_WIDTH + TEXT_PADDING;
    CreateLabel(DASH_PREFIX + "AI_SubSlave", "Slave Account", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_SLAVE_WIDTH + TEXT_PADDING;
    CreateLabel(DASH_PREFIX + "AI_SubStatus", "Connection", x + COL_REMARKS_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    // Account Number row
    x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "AI_AccBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_DATA);
    CreateLabel(OBJ_AI_ACC_LABEL, "Account:", x + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_AI_ACC_PROP, "...", x + COL_PROP_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_PROP_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_AI_ACC_SLAVE, "...", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    // Balance row
    x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "AI_BalBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_DATA);
    CreateLabel(OBJ_AI_BAL_LABEL, "Balance:", x + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_AI_BAL_PROP, "0.00", x + COL_PROP_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_PROP_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_AI_BAL_SLAVE, "0.00", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    // Equity row
    x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "AI_EqBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_DATA);
    CreateLabel(OBJ_AI_EQ_LABEL, "Equity:", x + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    x += COL_LABEL_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_AI_EQ_PROP, "0.00", x + COL_PROP_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    x += COL_PROP_WIDTH + TEXT_PADDING;
    CreateLabel(OBJ_AI_EQ_SLAVE, "0.00", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    // Connection status row
    x = DASH_START_X;
    CreateBackground(DASH_PREFIX + "AI_ConnBg", x, y, section_width, ROW_HEIGHT, COLOR_BG_DATA);
    CreateLabel(OBJ_AI_CONN_LABEL, "Slave Link:", x + TEXT_PADDING, y + ROW_HEIGHT/2, COLOR_TEXT_NORMAL, 9, ANCHOR_LEFT);
    x += COL_LABEL_WIDTH + TEXT_PADDING + COL_PROP_WIDTH + TEXT_PADDING; // Skip prop column
    CreateLabel(OBJ_AI_CONN_STATUS, "Checking...", x + COL_SLAVE_WIDTH/2, y + ROW_HEIGHT/2, COLOR_TEXT_WARNING, 9, ANCHOR_CENTER);
    y += ROW_HEIGHT;
    
    return y + SECTION_SPACING;
}

//+------------------------------------------------------------------+
//| Main Dashboard Functions (Interface for EA1)                    |
//+------------------------------------------------------------------+
void Dashboard_Init()
{
    Print("Dashboard_Init: Creating fresh dashboard...");
    
    // Clear any existing dashboard objects
    ObjectsDeleteAll(ChartID(), DASH_PREFIX);
    
    int current_y = DASH_START_Y;
    
    // Create sections
    current_y = CreateTopSection(current_y);
    current_y = CreateLiveTradingSection(current_y);
    current_y = CreateAccountInfoSection(current_y);
    
    ChartRedraw(ChartID());
    Print("Dashboard_Init: Fresh dashboard created successfully.");
}

void Dashboard_Deinit()
{
    ObjectsDeleteAll(ChartID(), DASH_PREFIX);
    ChartRedraw(ChartID());
    Print("Dashboard_Deinit: Dashboard cleaned up.");
}

void Dashboard_UpdateStaticInfo(string ea_version, int magic_number, double initial_challenge_balance_prop, 
                                double daily_dd_limit_pct_prop, double max_account_dd_pct_prop, 
                                double stage_target_pct_prop, int min_trading_days_prop, 
                                string symbol = "", string timeframe = "", double challenge_cost = 0)
{
    // Update master account info
    ObjectSetString(ChartID(), OBJ_AI_ACC_PROP, OBJPROP_TEXT, IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
    
    ChartRedraw(ChartID());
}

void Dashboard_UpdateDynamicInfo(double prop_balance, double prop_equity, double prop_balance_at_day_start, 
                                 double prop_peak_equity, int prop_current_trading_days, 
                                 bool session_active, double master_ea_volume,
                                 double daily_dd_floor_prop, double daily_dd_limit_prop,
                                 double max_dd_static_floor_prop, double max_dd_trailing_floor_prop, 
                                 double max_dd_limit_prop)
{
    // Update datetime
    ObjectSetString(ChartID(), OBJ_DATETIME, OBJPROP_TEXT, 
                    TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS) + " Server");
    
    // Update master volume
    ObjectSetString(ChartID(), OBJ_LT_VOLUME_PROP, OBJPROP_TEXT, DoubleToString(master_ea_volume, 2));
    
    // Update master balance and equity
    ObjectSetString(ChartID(), OBJ_AI_BAL_PROP, OBJPROP_TEXT, DoubleToString(prop_balance, 2));
    ObjectSetString(ChartID(), OBJ_AI_EQ_PROP, OBJPROP_TEXT, DoubleToString(prop_equity, 2));
    
    // Calculate and update daily PnL
    double daily_pnl = prop_equity - prop_balance_at_day_start;
    ObjectSetString(ChartID(), OBJ_LT_PNL_PROP, OBJPROP_TEXT, DoubleToString(daily_pnl, 2));
    ObjectSetInteger(ChartID(), OBJ_LT_PNL_PROP, OBJPROP_COLOR, 
                     daily_pnl >= 0 ? COLOR_TEXT_SUCCESS : COLOR_TEXT_DANGER);
    
    ChartRedraw(ChartID());
}

void Dashboard_UpdateStatus(string status_text, bool is_signal_active)
{
    ObjectSetString(ChartID(), OBJ_STATUS, OBJPROP_TEXT, status_text);
    
    color status_color = COLOR_TEXT_NORMAL;
    if(StringFind(status_text, "LONG") != -1 && is_signal_active)
        status_color = COLOR_TEXT_SUCCESS;
    else if(StringFind(status_text, "SHORT") != -1 && is_signal_active)
        status_color = COLOR_TEXT_DANGER;
    
    ObjectSetInteger(ChartID(), OBJ_STATUS, OBJPROP_COLOR, status_color);
    ChartRedraw(ChartID());
}

void Dashboard_UpdateSlaveStatus(string slave_status_text, double slave_balance, double slave_equity, 
                                 double slave_daily_pnl, bool slave_connected, long slave_account_number, 
                                 string slave_account_currency, double slave_open_volume, 
                                 int slave_leverage, string slave_server)
{
    // Update slave account info
    if(slave_account_number > 0)
        ObjectSetString(ChartID(), OBJ_AI_ACC_SLAVE, OBJPROP_TEXT, IntegerToString(slave_account_number));
    else
        ObjectSetString(ChartID(), OBJ_AI_ACC_SLAVE, OBJPROP_TEXT, "N/A");
    
    // Update slave balance and equity
    ObjectSetString(ChartID(), OBJ_AI_BAL_SLAVE, OBJPROP_TEXT, DoubleToString(slave_balance, 2));
    ObjectSetString(ChartID(), OBJ_AI_EQ_SLAVE, OBJPROP_TEXT, DoubleToString(slave_equity, 2));
    
    // Update slave volume
    ObjectSetString(ChartID(), OBJ_LT_VOLUME_SLAVE, OBJPROP_TEXT, DoubleToString(slave_open_volume, 2));
    
    // Update slave daily PnL
    ObjectSetString(ChartID(), OBJ_LT_PNL_SLAVE, OBJPROP_TEXT, DoubleToString(slave_daily_pnl, 2));
    ObjectSetInteger(ChartID(), OBJ_LT_PNL_SLAVE, OBJPROP_COLOR, 
                     slave_daily_pnl >= 0 ? COLOR_TEXT_SUCCESS : COLOR_TEXT_DANGER);
    
    // Update connection status
    string conn_text = slave_connected ? "Connected" : "DISCONNECTED";
    color conn_color = slave_connected ? COLOR_TEXT_SUCCESS : COLOR_TEXT_DANGER;
    ObjectSetString(ChartID(), OBJ_AI_CONN_STATUS, OBJPROP_TEXT, conn_text);
    ObjectSetInteger(ChartID(), OBJ_AI_CONN_STATUS, OBJPROP_COLOR, conn_color);
    
    ChartRedraw(ChartID());
}

//+------------------------------------------------------------------+
//| Chart Visual Functions (Placeholder - maintain interface)       |
//+------------------------------------------------------------------+
void ChartVisuals_InitPivots(bool show_visuals, color up_color, color down_color)
{
    // Placeholder for pivot visualization
}

void ChartVisuals_DeinitPivots()
{
    ObjectsDeleteAll(ChartID(), DASH_PREFIX + "Pivot", 0, -1);
    ChartRedraw(ChartID());
}

void ChartVisuals_UpdatePivots(bool show_visuals, color color_low_pivot_lines, color color_high_pivot_lines)
{
    // Placeholder for pivot visualization - simplified parameters
}

void ChartVisuals_UpdateMarketBias(double bias_value, bool show_visuals)
{
    // Placeholder for market bias visualization
}

void ChartVisuals_InitMarketBias(bool show_visuals, color up_color, color down_color)
{
    // Placeholder for market bias visualization
}

void ChartVisuals_DeinitMarketBias()
{
    ObjectsDeleteAll(ChartID(), DASH_PREFIX + "MarketBias", 0, -1);
    ChartRedraw(ChartID());
}

//+------------------------------------------------------------------+
//| Required Struct (for compatibility)                             |
//+------------------------------------------------------------------+
struct PivotPoint 
{
    datetime time;
    double price;
    PivotPoint() : time(0), price(0.0) {}
};

//+------------------------------------------------------------------+
//| End of Dashboard                                                 |
//+------------------------------------------------------------------+ 
