// SynPropEA1_Dashboard.mqh
// ------------------------
// Professional Prop Trading Dashboard (Revamped to match target design)
// Complete rewrite: updated color scheme, layout, object naming, and data‐display logic
// Compile with compile_local.sh to confirm zero errors/warnings.
//
// 2025.06.XX  Updated by ChatGPT

// --- GLOBAL DASHBOARD STATE VARIABLES ---
static bool g_dashboard_initialized = false;
static bool g_dashboard_visible = true;
static string g_ea_version_dash = "N/A";
static string g_ea_build_dash = "N/A"; 
static datetime g_last_real_account_update_time = 0;

// External variables from main EA
extern double g_challenge_cost;

// External drawdown tracking variables
extern double g_all_time_high;
extern double g_daily_high;
extern int g_last_day_dd;

// --- STRUCTURE DEFINITIONS ---
struct PivotPoint
{
    datetime time;
    double price;
};

// --- COLOR CONSTANTS (match target) ---
#define COLOR_BG_HEADER_YELLOW       C'255,255,153'
#define COLOR_BG_STATUS_GREEN        C'144,238,144'
#define COLOR_BG_STATUS_ORANGE       C'255,218,185'
#define COLOR_BG_SECTION_PURPLE      C'138,43,226'
#define COLOR_BG_ROW_LIGHT_PURPLE    C'221,160,221'
#define COLOR_BG_ACC_HEADER_GREY     C'192,192,192'
#define COLOR_BG_COST_RECOVERY       C'255,255,224'

#define COLOR_TEXT_WHITE             clrWhite
#define COLOR_TEXT_BLACK             clrBlack
#define COLOR_TEXT_GREEN             C'0,128,0'
#define COLOR_TEXT_RED               C'220,20,60'
#define COLOR_TEXT_BLUE              C'25,25,112'
#define COLOR_TEXT_ORANGE            C'255,165,0'  // Added for hedge loss medium status

// Additional color definitions for PnL sections
#define COLOR_BG_DPNL_SECTION    C'173,216,230'  // Light blue for Daily PnL
#define COLOR_BG_CPNL_SECTION    C'144,238,144'  // Light green for Cumulative PnL

// --- LAYOUT CONSTANTS ---
#define DASH_PREFIX           "SynProp_"
#define DASH_START_X          10
#define DASH_START_Y          25

#define COL_LABEL_WIDTH       160
#define COL_PROP_WIDTH        100
#define COL_REAL_WIDTH        100
#define COL_REMARKS_WIDTH     110

#define ROW_HEIGHT_STD        18
#define ROW_HEIGHT_HEADER     20
#define PADDING               5

// --- TEXT STYLE CONSTANTS ---
#define TEXT_FONT_STD              "Arial"        // Standard font
#define TEXT_FONT_SIZE_STD         9              // Standard font size for most text
#define TEXT_FONT_SIZE_HEADER      10             // Font size for section headers
#define TEXT_FONT_SIZE_REMARKS     8              // Smaller font size for remarks/details
#define TextColor_Neutral          COLOR_TEXT_BLACK // Neutral text color
#define TextColor_Normal           COLOR_TEXT_BLACK // Normal dynamic text
#define TextColor_Alert            COLOR_TEXT_RED   // Alert text color (e.g., for DD warnings)
#define TextColor_Positive         COLOR_TEXT_GREEN // Positive PnL, good status
#define TextColor_Negative         COLOR_TEXT_RED   // Negative PnL
#define TextColor_Remarks          C'105,105,105' // DimGray for remarks

// --- OBJECT NAME DEFINITIONS ---
// Timestamp
#define OBJ_TIMESTAMP_LABEL      DASH_PREFIX "Timestamp"

// STATUS SECTION
#define OBJ_STATUS_BG            DASH_PREFIX "StatusBg"
#define OBJ_STATUS_LABEL         DASH_PREFIX "StatusLabel"
#define OBJ_STATUS_VALUE         DASH_PREFIX "StatusValue"
#define OBJ_WMODE_BG             DASH_PREFIX "WModeBg"
#define OBJ_WMODE_LABEL          DASH_PREFIX "WModeLabel"
#define OBJ_WMODE_VALUE          DASH_PREFIX "WModeValue"

// LIVE TRADING SECTION
#define OBJ_LIVE_HEADER_BG       DASH_PREFIX "LiveHeaderBg"
#define OBJ_LIVE_HEADER_TITLE    DASH_PREFIX "LiveHeaderTitle"
#define OBJ_LIVE_HEADER_PROP     DASH_PREFIX "LiveHeaderProp"
#define OBJ_LIVE_HEADER_REAL     DASH_PREFIX "LiveHeaderReal"
#define OBJ_LIVE_HEADER_REMARKS  DASH_PREFIX "LiveHeaderRemarks"

#define OBJ_VOL_LABEL            DASH_PREFIX "VolLabel"
#define OBJ_VOL_PROP             DASH_PREFIX "VolProp"
#define OBJ_VOL_REAL             DASH_PREFIX "VolReal"
#define OBJ_VOL_REMARKS          DASH_PREFIX "VolRemarks"

#define OBJ_DPNL_LABEL           DASH_PREFIX "DPNLLabel"
#define OBJ_DPNL_PROP            DASH_PREFIX "DPNLProp"
#define OBJ_DPNL_REAL            DASH_PREFIX "DPNLReal"
#define OBJ_DPNL_REMARKS         DASH_PREFIX "DPNLRemarks"

#define OBJ_SPNL_LABEL           DASH_PREFIX "SPNLLabel"
#define OBJ_SPNL_PROP            DASH_PREFIX "SPNLProp"
#define OBJ_SPNL_REAL            DASH_PREFIX "SPNLReal"
#define OBJ_SPNL_REMARKS         DASH_PREFIX "SPNLRemarks"

#define OBJ_SWAP_LABEL           DASH_PREFIX "SwapLabel"
#define OBJ_SWAP_PROP            DASH_PREFIX "SwapProp"
#define OBJ_SWAP_REAL            DASH_PREFIX "SwapReal"
#define OBJ_SWAP_REMARKS         DASH_PREFIX "SwapRemarks"

#define OBJ_HEDGE_LABEL          DASH_PREFIX "HedgeLabel"
#define OBJ_HEDGE_PROP           DASH_PREFIX "HedgeProp"
#define OBJ_HEDGE_REAL           DASH_PREFIX "HedgeReal"
#define OBJ_HEDGE_REMARKS        DASH_PREFIX "HedgeRemarks"

#define OBJ_DAYS_LABEL           DASH_PREFIX "DaysLabel"
#define OBJ_DAYS_PROP            DASH_PREFIX "DaysProp"
#define OBJ_DAYS_REAL            DASH_PREFIX "DaysReal"
#define OBJ_DAYS_REMARKS         DASH_PREFIX "DaysRemarks"

// ACCOUNT STATUS SECTION
#define OBJ_ACC_HEADER_BG        DASH_PREFIX "AccHeaderBg"
#define OBJ_ACC_HEADER_TITLE     DASH_PREFIX "AccHeaderTitle"
#define OBJ_ACC_HEADER_PROP      DASH_PREFIX "AccHeaderProp"
#define OBJ_ACC_HEADER_REAL      DASH_PREFIX "AccHeaderReal"
#define OBJ_ACC_HEADER_REMARKS   DASH_PREFIX "AccHeaderRemarks"

#define OBJ_ACC_NUM_LABEL        DASH_PREFIX "AccNumLabel"
#define OBJ_ACC_NUM_PROP         DASH_PREFIX "AccNumProp"
#define OBJ_ACC_NUM_REAL         DASH_PREFIX "AccNumReal"
#define OBJ_ACC_NUM_REMARKS      DASH_PREFIX "AccNumRemarks"

#define OBJ_CURR_LABEL           DASH_PREFIX "CurrLabel"
#define OBJ_CURR_PROP            DASH_PREFIX "CurrProp"
#define OBJ_CURR_REAL            DASH_PREFIX "CurrReal"
#define OBJ_CURR_REMARKS         DASH_PREFIX "CurrRemarks"

#define OBJ_FMGN_LABEL           DASH_PREFIX "FMgnLabel"
#define OBJ_FMGN_PROP            DASH_PREFIX "FMgnProp"
#define OBJ_FMGN_REAL            DASH_PREFIX "FMgnReal"
#define OBJ_FMGN_REMARKS         DASH_PREFIX "FMgnRemarks"

#define OBJ_SYM_LABEL            DASH_PREFIX "SymLabel"
#define OBJ_SYM_PROP             DASH_PREFIX "SymProp"
#define OBJ_SYM_REAL             DASH_PREFIX "SymReal"
#define OBJ_SYM_REMARKS          DASH_PREFIX "SymRemarks"

#define OBJ_DDTYPE_LABEL         DASH_PREFIX "DDTypeLabel"
#define OBJ_DDTYPE_PROP          DASH_PREFIX "DDTypeProp"
#define OBJ_DDTYPE_REAL          DASH_PREFIX "DDTypeReal"
#define OBJ_DDTYPE_REMARKS       DASH_PREFIX "DDTypeRemarks"

#define OBJ_TODDD_LABEL          DASH_PREFIX "ToDDDLabel"
#define OBJ_TODDD_PROP           DASH_PREFIX "ToDDDProp"
#define OBJ_TODDD_REAL           DASH_PREFIX "ToDDDReal"
#define OBJ_TODDD_REMARKS        DASH_PREFIX "ToDDDRemarks"

#define OBJ_MAXDD_LABEL          DASH_PREFIX "MaxDDLabel"
#define OBJ_MAXDD_PROP           DASH_PREFIX "MaxDDProp"
#define OBJ_MAXDD_REAL           DASH_PREFIX "MaxDDReal"
#define OBJ_MAXDD_REMARKS        DASH_PREFIX "MaxDDRemarks"

#define OBJ_BALEQ_LABEL          DASH_PREFIX "BalEqLabel"
#define OBJ_BALEQ_PROP           DASH_PREFIX "BalEqProp"
#define OBJ_BALEQ_REAL           DASH_PREFIX "BalEqReal"
#define OBJ_BALEQ_REMARKS        DASH_PREFIX "BalEqRemarks"

// COST RECOVERY SECTION
#define OBJ_CR_HEADER_BG         DASH_PREFIX "CRHeaderBg"
#define OBJ_CR_HEADER_TITLE      DASH_PREFIX "CRHeaderTitle"
#define OBJ_CR_LOSS_LABEL        DASH_PREFIX "CRLossLabel"
#define OBJ_CR_PROFIT_LABEL      DASH_PREFIX "CRProfitLabel"
#define OBJ_CR_RECOVERY_LABEL    DASH_PREFIX "CRRecoveryLabel"

#define OBJ_CR_DDD_LABEL         DASH_PREFIX "CRDDDLabel"
#define OBJ_CR_DDD_LOSS          DASH_PREFIX "CRDDDLoss"
#define OBJ_CR_DDD_PROFIT        DASH_PREFIX "CRDDDProfit"
#define OBJ_CR_DDD_RECOVERY      DASH_PREFIX "CRDDDRecovery"

#define OBJ_CR_MDD_LABEL         DASH_PREFIX "CRMDDLabel"
#define OBJ_CR_MDD_LOSS          DASH_PREFIX "CRMDDLoss"
#define OBJ_CR_MDD_PROFIT        DASH_PREFIX "CRMDDProfit"
#define OBJ_CR_MDD_RECOVERY      DASH_PREFIX "CRMDDRecovery"

// DAILY PNL BREAKDOWN SECTION
#define OBJ_DPNL_SECTION_BG      DASH_PREFIX "DPNLSectionBg"
#define OBJ_DPNL_SECTION_TITLE   DASH_PREFIX "DPNLSectionTitle"
#define OBJ_DPNL_SECTION_PROP    DASH_PREFIX "DPNLSectionProp"
#define OBJ_DPNL_SECTION_REAL    DASH_PREFIX "DPNLSectionReal"
#define OBJ_DPNL_SECTION_REMARKS DASH_PREFIX "DPNLSectionRemarks"

#define OBJ_DPNL_TOTAL_LABEL     DASH_PREFIX "DPNLTotalLabel"
#define OBJ_DPNL_TOTAL_PROP      DASH_PREFIX "DPNLTotalProp"
#define OBJ_DPNL_TOTAL_REAL      DASH_PREFIX "DPNLTotalReal"
#define OBJ_DPNL_TOTAL_REMARKS   DASH_PREFIX "DPNLTotalRemarks"

#define OBJ_DPNL_REALIZED_LABEL  DASH_PREFIX "DPNLRealizedLabel"
#define OBJ_DPNL_REALIZED_PROP   DASH_PREFIX "DPNLRealizedProp"
#define OBJ_DPNL_REALIZED_REAL   DASH_PREFIX "DPNLRealizedReal"
#define OBJ_DPNL_REALIZED_REMARKS DASH_PREFIX "DPNLRealizedRemarks"

#define OBJ_DPNL_UNREALIZED_LABEL DASH_PREFIX "DPNLUnrealizedLabel"
#define OBJ_DPNL_UNREALIZED_PROP  DASH_PREFIX "DPNLUnrealizedProp"
#define OBJ_DPNL_UNREALIZED_REAL  DASH_PREFIX "DPNLUnrealizedReal"
#define OBJ_DPNL_UNREALIZED_REMARKS DASH_PREFIX "DPNLUnrealizedRemarks"

// CUMULATIVE PNL TRACKING SECTION
#define OBJ_CPNL_SECTION_BG      DASH_PREFIX "CPNLSectionBg"
#define OBJ_CPNL_SECTION_TITLE   DASH_PREFIX "CPNLSectionTitle"
#define OBJ_CPNL_SECTION_PROP    DASH_PREFIX "CPNLSectionProp"
#define OBJ_CPNL_SECTION_REAL    DASH_PREFIX "CPNLSectionReal"
#define OBJ_CPNL_SECTION_REMARKS DASH_PREFIX "CPNLSectionRemarks"

#define OBJ_CPNL_TOTAL_LABEL     DASH_PREFIX "CPNLTotalLabel"
#define OBJ_CPNL_TOTAL_PROP      DASH_PREFIX "CPNLTotalProp"
#define OBJ_CPNL_TOTAL_REAL      DASH_PREFIX "CPNLTotalReal"
#define OBJ_CPNL_TOTAL_REMARKS   DASH_PREFIX "CPNLTotalRemarks"

#define OBJ_CPNL_DRAWDOWN_LABEL  DASH_PREFIX "CPNLDrawdownLabel"
#define OBJ_CPNL_DRAWDOWN_PROP   DASH_PREFIX "CPNLDrawdownProp"
#define OBJ_CPNL_DRAWDOWN_REAL   DASH_PREFIX "CPNLDrawdownReal"
#define OBJ_CPNL_DRAWDOWN_REMARKS DASH_PREFIX "CPNLDrawdownRemarks"

#define OBJ_CPNL_RETURN_LABEL    DASH_PREFIX "CPNLReturnLabel"
#define OBJ_CPNL_RETURN_PROP     DASH_PREFIX "CPNLReturnProp"
#define OBJ_CPNL_RETURN_REAL     DASH_PREFIX "CPNLReturnReal"
#define OBJ_CPNL_RETURN_REMARKS  DASH_PREFIX "CPNLReturnRemarks"

// DRAWDOWN DASHBOARD SECTION
#define OBJ_DD_PANEL_BG          DASH_PREFIX "DDPanelBg"
#define OBJ_DD_DAILY_LABEL       DASH_PREFIX "DDDailyLabel"
#define OBJ_DD_MAX_LABEL         DASH_PREFIX "DDMaxLabel"
#define OBJ_DD_DAILY_BAR_BACK    DASH_PREFIX "DDDailyBarBack"
#define OBJ_DD_DAILY_BAR_FILL    DASH_PREFIX "DDDailyBarFill"
#define OBJ_DD_MAX_BAR_BACK      DASH_PREFIX "DDMaxBarBack"
#define OBJ_DD_MAX_BAR_FILL      DASH_PREFIX "DDMaxBarFill"

// --- HELPER FUNCTIONS ---
void CreateRectangle(long chart_id, string name, int x, int y, int width, int height, color bgColor, int zOrder=0)
{
    ObjectDelete(chart_id, name);
    if(ObjectCreate(chart_id, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
    {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, "");
        ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE, false);
        ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(chart_id, name, OBJPROP_XSIZE, width);
        ObjectSetInteger(chart_id, name, OBJPROP_YSIZE, height);
        ObjectSetInteger(chart_id, name, OBJPROP_BGCOLOR, bgColor);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, bgColor);
        ObjectSetInteger(chart_id, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
        ObjectSetInteger(chart_id, name, OBJPROP_ZORDER, zOrder);
        ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
    }
}

void CreateText(long chart_id, string name, string text, int x, int y, color txtColor, int fontSize=9, string font="Arial", ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, int zOrder=1, color bgColor=CLR_NONE)
{
    ObjectDelete(chart_id, name);
    if(ObjectCreate(chart_id, name, OBJ_LABEL, 0, 0, 0))
    {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
        ObjectSetInteger(chart_id, name, OBJPROP_XDISTANCE, x);
        ObjectSetInteger(chart_id, name, OBJPROP_YDISTANCE, y);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, txtColor);
        ObjectSetInteger(chart_id, name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetString(chart_id, name, OBJPROP_FONT, font);
        ObjectSetInteger(chart_id, name, OBJPROP_ANCHOR, anchor);
        ObjectSetInteger(chart_id, name, OBJPROP_ZORDER, zOrder);
        if(bgColor != CLR_NONE)
        {
            ObjectSetInteger(chart_id, name, OBJPROP_BGCOLOR, bgColor);
            ObjectSetInteger(chart_id, name, OBJPROP_BACK, false);
        }
        else
        {
            ObjectSetInteger(chart_id, name, OBJPROP_BACK, true);
        }
    }
}

// ADDED HELPER FUNCTION
void ObjectSetText(long chart_id, string name, string text, int fontSize, string font, color txtColor, ENUM_ANCHOR_POINT anchor = ANCHOR_LEFT_UPPER, int zOrder = 1)
{
    if(ObjectFind(chart_id, name) != -1) // Check if object exists
    {
        ObjectSetString(chart_id, name, OBJPROP_TEXT, text);
        ObjectSetInteger(chart_id, name, OBJPROP_FONTSIZE, fontSize);
        ObjectSetString(chart_id, name, OBJPROP_FONT, font);
        ObjectSetInteger(chart_id, name, OBJPROP_COLOR, txtColor);
        ObjectSetInteger(chart_id, name, OBJPROP_ANCHOR, anchor); // Optional: allow anchor update
        ObjectSetInteger(chart_id, name, OBJPROP_ZORDER, zOrder);   // Optional: allow z-order update
    }
}

// --- DASHBOARD INITIALIZATION ---
void Dashboard_Init()
{
    if(g_dashboard_initialized) 
    {
        Print("Dashboard_Init: Already initialized, skipping");
        return;
    }
    
    Print("Dashboard_Init: Starting initialization...");
    
    long chart_id = ChartID();
    if(chart_id == 0)
    {
        Print("Dashboard_Init: Invalid chart ID, aborting");
        return;
    }

    // Clear any existing dashboard objects first
    ObjectsDeleteAll(chart_id, DASH_PREFIX);
    Sleep(100); // Small delay to ensure objects are cleared
    
    int curX = DASH_START_X;
    int curY = DASH_START_Y;

    // 1) TIMESTAMP (top‐right corner)
    int chartWidthPx = (int)ChartGetInteger(chart_id, CHART_WIDTH_IN_PIXELS);
    int tsX = chartWidthPx - 200;
    CreateText(chart_id, OBJ_TIMESTAMP_LABEL, StringFormat("%s Server", TimeToString(TimeTradeServer(), TIME_DATE|TIME_SECONDS)),
               tsX, curY - ROW_HEIGHT_STD - 2, COLOR_TEXT_BLACK, 8, "Arial", ANCHOR_RIGHT);

    // Calculate total width of the main sections:
    int totalWidth = COL_LABEL_WIDTH + COL_PROP_WIDTH + COL_REAL_WIDTH + COL_REMARKS_WIDTH + 3 * PADDING;

    // --- STATUS SECTION ---
    // A) STATUS Row (Green background)
    CreateRectangle(chart_id, OBJ_STATUS_BG, curX, curY, totalWidth, ROW_HEIGHT_STD, COLOR_BG_STATUS_GREEN);
    CreateText(chart_id, OBJ_STATUS_LABEL, "Status",
               curX + PADDING, curY + ROW_HEIGHT_STD/2, COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    CreateText(chart_id, OBJ_STATUS_VALUE, "Connected / Working / Show All History",
               curX + COL_LABEL_WIDTH + 2*PADDING, curY + ROW_HEIGHT_STD/2, COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // B) WORKING MODE Row (Orange background)
    CreateRectangle(chart_id, OBJ_WMODE_BG, curX, curY, totalWidth, ROW_HEIGHT_STD, COLOR_BG_STATUS_ORANGE);
    CreateText(chart_id, OBJ_WMODE_LABEL, "Working mode",
               curX + PADDING, curY + ROW_HEIGHT_STD/2, COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    CreateText(chart_id, OBJ_WMODE_VALUE, "Prop (Manual)",
               curX + COL_LABEL_WIDTH + 2*PADDING, curY + ROW_HEIGHT_STD/2, COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD + 2 * PADDING;

    // --- LIVE TRADING INFORMATION SECTION ---
    // Header Row (Dark Purple background)
    CreateRectangle(chart_id, OBJ_LIVE_HEADER_BG, curX, curY, totalWidth, ROW_HEIGHT_HEADER, COLOR_BG_SECTION_PURPLE);
    int cellX = curX;
    CreateText(chart_id, OBJ_LIVE_HEADER_TITLE, "Live Trading Information",
               cellX + (COL_LABEL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_WHITE, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_LIVE_HEADER_PROP, "Prop Account",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_WHITE, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateText(chart_id, OBJ_LIVE_HEADER_REAL, "Real Account",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_WHITE, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_LIVE_HEADER_REMARKS, "Remarks",
               cellX + (COL_REMARKS_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_WHITE, 10, "Arial", ANCHOR_CENTER);
    curY += ROW_HEIGHT_HEADER;

    // 1) VOLUME Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_VOL_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_VOL_LABEL, "Volume",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_VOL_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_VOL_PROP, "1.48", cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_VOL_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_VOL_REAL, "0.26", cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_VOL_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_VOL_REMARKS, "Projection (5.71 ratio)",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 2) DAILY PnL Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_DPNL_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_LABEL, "Daily PnL",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_PROP, "0.00",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLUE, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_REAL, "0.00",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLUE, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_REMARKS, "",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 3) SUMMARY PnL Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_SPNL_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SPNL_LABEL, "Summary PnL",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SPNL_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SPNL_PROP, "0.00 / TBD",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLUE, 9, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SPNL_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SPNL_REAL, "0.00 / TBD",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLUE, 9, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SPNL_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SPNL_REMARKS, "0.00 % / 0.00 %",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 8, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 4) SWAPS & COMMISSION Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_SWAP_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SWAP_LABEL, "Swaps & Commission",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SWAP_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SWAP_PROP, "0.00",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SWAP_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SWAP_REAL, "0.00",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SWAP_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SWAP_REMARKS, "",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 4.5) HEDGE LOSS Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_HEDGE_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_HEDGE_LABEL, "Hedge Loss",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_HEDGE_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_HEDGE_PROP, "N/A",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_HEDGE_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_HEDGE_REAL, "$0.00 (0.0%)",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_HEDGE_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_HEDGE_REMARKS, "Smart Adaptive",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 5) TRADING DAYS Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_DAYS_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DAYS_LABEL, "Trading Days",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DAYS_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DAYS_PROP, "8 / 4",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DAYS_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DAYS_REAL, "0/0",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DAYS_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DAYS_REMARKS, "",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD + 2 * PADDING;

    // --- ACCOUNT STATUS SECTION ---
    // Header (grey)
    CreateRectangle(chart_id, OBJ_ACC_HEADER_BG, curX, curY, totalWidth, ROW_HEIGHT_HEADER, COLOR_BG_ACC_HEADER_GREY);
    cellX = curX;
    CreateText(chart_id, OBJ_ACC_HEADER_TITLE, "Account Status",
               cellX + (COL_LABEL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_ACC_HEADER_PROP, "Prop Account",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateText(chart_id, OBJ_ACC_HEADER_REAL, "Real Account",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_ACC_HEADER_REMARKS, "Remarks",
               cellX + (COL_REMARKS_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    curY += ROW_HEIGHT_HEADER;

    // 1) ACCOUNT NUMBER Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_ACC_NUM_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_ACC_NUM_LABEL, "Account",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_ACC_NUM_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_ACC_NUM_PROP, "540222033",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_ACC_NUM_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_ACC_NUM_REAL, "2100139103",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_ACC_NUM_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_ACC_NUM_REMARKS, "Ok",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 2) CURRENCY Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_CURR_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CURR_LABEL, "Account Currency",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CURR_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CURR_PROP, "EUR",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CURR_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CURR_REAL, "EUR",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CURR_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CURR_REMARKS, "Match",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 3) FREE MARGIN Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_FMGN_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_FMGN_LABEL, "Free margin",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_FMGN_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_FMGN_PROP, "39670.76",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_FMGN_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_FMGN_REAL, "1073.50",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_FMGN_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_FMGN_REMARKS, "Sufficient",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 4) SYMBOL Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_SYM_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SYM_LABEL, "Symbol",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SYM_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SYM_PROP, "GBPUSD",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_RED, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SYM_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SYM_REAL, "GBPUSD",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_RED, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_SYM_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_SYM_REMARKS, "Market closed",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_RED, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 5) DAILY DD TYPE Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_DDTYPE_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DDTYPE_LABEL, "Daily DD Type",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DDTYPE_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DDTYPE_PROP, "Balance & Equity",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 8, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DDTYPE_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DDTYPE_REAL, "",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 8, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DDTYPE_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DDTYPE_REMARKS, "",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 6) TODAY ALLOWED DD Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_TODDD_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_TODDD_LABEL, "Today Allowed DD",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_TODDD_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_TODDD_PROP, "TBD / TBD",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 8, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_TODDD_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_TODDD_REAL, "",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 8, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_TODDD_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_TODDD_REMARKS, "TBD %",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 7) MAX ALLOWED DD Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_MAXDD_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_MAXDD_LABEL, "Max Allowed DD",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_MAXDD_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_MAXDD_PROP, "TBD / TBD",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 8, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_MAXDD_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_MAXDD_REAL, "",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 8, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_MAXDD_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_MAXDD_REMARKS, "TBD %",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 8) BALANCE & EQUITY Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_BALEQ_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_BALEQ_LABEL, "Balance & Equity",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_BALEQ_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_BALEQ_PROP, "25000.00",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLUE, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_BALEQ_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_BALEQ_REAL, "0.00",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLUE, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_BALEQ_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_BALEQ_REMARKS, "Last Upd: Waiting...",
               cellX + COL_REMARKS_WIDTH / 2, curY + ROW_HEIGHT_STD / 2, 
               TextColor_Remarks, TEXT_FONT_SIZE_REMARKS, TEXT_FONT_STD, ANCHOR_CENTER);
    curY += ROW_HEIGHT_STD;

    // --- COST RECOVERY SECTION ---
    CreateRectangle(chart_id, OBJ_CR_HEADER_BG, curX, curY, totalWidth, ROW_HEIGHT_HEADER, COLOR_BG_COST_RECOVERY);
    cellX = curX;
    CreateText(chart_id, OBJ_CR_HEADER_TITLE, "Cost Recovery Estimate",
               cellX + (COL_LABEL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_CR_LOSS_LABEL, "Loss on Prop",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateText(chart_id, OBJ_CR_PROFIT_LABEL, "Profit on Real",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_CR_RECOVERY_LABEL, "Recovery",
               cellX + (COL_REMARKS_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    curY += ROW_HEIGHT_HEADER;

    // A) DAILY DD RECOVERY Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_CR_DDD_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_DDD_LABEL, "Daily DD",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CR_DDD_LOSS + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_DDD_LOSS, "-1699.98",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_RED, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CR_DDD_PROFIT + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_DDD_PROFIT, "297.45",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CR_DDD_RECOVERY + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_DDD_RECOVERY, "0.0 %",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // B) MAX DD RECOVERY Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_CR_MDD_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_MDD_LABEL, "Max DD",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CR_MDD_LOSS + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_MDD_LOSS, "-3999.32",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_RED, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CR_MDD_PROFIT + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_MDD_PROFIT, "699.77",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_GREEN, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CR_MDD_RECOVERY + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CR_MDD_RECOVERY, "0.0 %",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD + 2 * PADDING;

    // --- DAILY PNL BREAKDOWN SECTION ---
    CreateRectangle(chart_id, OBJ_DPNL_SECTION_BG, curX, curY, totalWidth, ROW_HEIGHT_HEADER, COLOR_BG_DPNL_SECTION);
    cellX = curX;
    CreateText(chart_id, OBJ_DPNL_SECTION_TITLE, "Daily PnL Breakdown",
               cellX + (COL_LABEL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_DPNL_SECTION_PROP, "Prop Account",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateText(chart_id, OBJ_DPNL_SECTION_REAL, "Real Account",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_DPNL_SECTION_REMARKS, "Status",
               cellX + (COL_REMARKS_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    curY += ROW_HEIGHT_HEADER;

    // 1) Total Daily PnL Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_DPNL_TOTAL_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_TOTAL_LABEL, "Total Daily PnL",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_TOTAL_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_TOTAL_PROP, "0.00",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_TOTAL_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_TOTAL_REAL, "0.00",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_TOTAL_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_TOTAL_REMARKS, "00:01-23:59",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 2) Realized PnL Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_DPNL_REALIZED_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_REALIZED_LABEL, "Realized PnL",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_REALIZED_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_REALIZED_PROP, "0.00",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_REALIZED_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_REALIZED_REAL, "0.00",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_REALIZED_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_REALIZED_REMARKS, "Closed Trades",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 3) Unrealized PnL Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_DPNL_UNREALIZED_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_UNREALIZED_LABEL, "Unrealized PnL",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_UNREALIZED_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_UNREALIZED_PROP, "0.00",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_UNREALIZED_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_UNREALIZED_REAL, "0.00",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_DPNL_UNREALIZED_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_DPNL_UNREALIZED_REMARKS, "Open Positions",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD + 2 * PADDING;

    // --- CUMULATIVE PNL TRACKING SECTION ---
    CreateRectangle(chart_id, OBJ_CPNL_SECTION_BG, curX, curY, totalWidth, ROW_HEIGHT_HEADER, COLOR_BG_CPNL_SECTION);
    cellX = curX;
    CreateText(chart_id, OBJ_CPNL_SECTION_TITLE, "Cumulative PnL Tracking",
               cellX + (COL_LABEL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_CPNL_SECTION_PROP, "Prop Account",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateText(chart_id, OBJ_CPNL_SECTION_REAL, "Real Account",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateText(chart_id, OBJ_CPNL_SECTION_REMARKS, "Performance",
               cellX + (COL_REMARKS_WIDTH/2), curY + (ROW_HEIGHT_HEADER/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    curY += ROW_HEIGHT_HEADER;

    // 1) Total Cumulative PnL Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_CPNL_TOTAL_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_TOTAL_LABEL, "Total Cumulative",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_TOTAL_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_TOTAL_PROP, "0.00",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_TOTAL_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_TOTAL_REAL, "0.00",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_TOTAL_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_TOTAL_REMARKS, "Since Start",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 2) Max Drawdown Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_CPNL_DRAWDOWN_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_DRAWDOWN_LABEL, "Max Drawdown",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_DRAWDOWN_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_DRAWDOWN_PROP, "0.00%",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_DRAWDOWN_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_DRAWDOWN_REAL, "0.00%",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_DRAWDOWN_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_DRAWDOWN_REMARKS, "Peak to Trough",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // 3) Annualized Return Row
    cellX = curX;
    CreateRectangle(chart_id, OBJ_CPNL_RETURN_LABEL + "_bg", cellX, curY, COL_LABEL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_RETURN_LABEL, "Annualized Return",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    cellX += COL_LABEL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_RETURN_PROP + "_bg", cellX, curY, COL_PROP_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_RETURN_PROP, "0.00%",
               cellX + (COL_PROP_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_PROP_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_RETURN_REAL + "_bg", cellX, curY, COL_REAL_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_RETURN_REAL, "0.00%",
               cellX + (COL_REAL_WIDTH/2), curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 10, "Arial", ANCHOR_CENTER);
    cellX += COL_REAL_WIDTH + PADDING;
    CreateRectangle(chart_id, OBJ_CPNL_RETURN_REMARKS + "_bg", cellX, curY, COL_REMARKS_WIDTH, ROW_HEIGHT_STD, COLOR_BG_ROW_LIGHT_PURPLE);
    CreateText(chart_id, OBJ_CPNL_RETURN_REMARKS, "Year-over-Year",
               cellX + PADDING, curY + (ROW_HEIGHT_STD/2), COLOR_TEXT_BLACK, 9, "Arial", ANCHOR_LEFT);
    curY += ROW_HEIGHT_STD;

    // Create Drawdown Dashboard if enabled
    // Note: InpShowDrawdownDashboard is accessed from main EA
    CreateDrawdownDashboard(chart_id, curY + PADDING * 2);

    // Final redraw and summary
    ChartRedraw(chart_id);
    Print("Dashboard_Init: Completed successfully with Daily PnL, Cumulative PnL, and Drawdown Dashboard sections.");

    g_dashboard_initialized = true;
}

// --- DASHBOARD DEINIT (cleanup) ---
void Dashboard_Deinit()
{
    long chart_id = ChartID();
    ObjectsDeleteAll(chart_id, DASH_PREFIX);
    g_dashboard_initialized = false; // Reset the initialization flag
    ChartRedraw(chart_id);
    Print("Dashboard_Deinit: All dashboard objects removed and flag reset");
}

// --- UPDATE FUNCTIONS ---
// Note: The following update routines reference the new object names exactly as defined above.
//       They must be called from within your EA's OnTick or equivalent logic, passing real-time data.
//       For brevity, only the skeleton signatures are provided; update contents refer to new names.

void Dashboard_UpdateStaticInfo(string ea_version,
                                int magic_number,
                                double initial_balance_prop,
                                double daily_dd_pct_prop,
                                double max_acc_dd_pct_prop,
                                double stage_target_pct_prop,
                                int min_days_prop,
                                string symbol = "",
                                string timeframe = "",
                                double cost = 0.0)
{
    long chart_id = ChartID();

    // 1) Update Working Mode Text
    string working_mode = "Prop (Auto)";
    if(symbol != "" && timeframe != "") working_mode = "Prop (Manual)";
    if(ObjectFind(chart_id, OBJ_WMODE_VALUE) != -1)
    {
        ObjectSetString(chart_id, OBJ_WMODE_VALUE, OBJPROP_TEXT, working_mode);
    }

    // 2) Update Timestamp
    string ts = StringFormat("%s Server", TimeToString(TimeTradeServer(), TIME_DATE|TIME_SECONDS));
    if(ObjectFind(chart_id, OBJ_TIMESTAMP_LABEL) != -1)
    {
        ObjectSetString(chart_id, OBJ_TIMESTAMP_LABEL, OBJPROP_TEXT, ts);
    }

    // 4) Store Static Values for PnL/Drawdown calculations
    static bool values_initialized = false;
    static double g_initial_balance_prop;
    static double g_max_daily_dd_abs_prop;
    static double g_max_acc_dd_abs_prop;
    static double g_stage_target_abs_prop;
    static int g_min_days_prop_total;
    
    if (!values_initialized)
    {
        g_initial_balance_prop = initial_balance_prop;
        g_max_daily_dd_abs_prop = (initial_balance_prop * daily_dd_pct_prop / 100.0);
        g_max_acc_dd_abs_prop = (initial_balance_prop * max_acc_dd_pct_prop / 100.0);
        g_stage_target_abs_prop = (initial_balance_prop * stage_target_pct_prop / 100.0);
        g_min_days_prop_total = min_days_prop;
        values_initialized = true;
    }
    // Note: g_challenge_cost is now external - value comes from main EA

    // 5) Update Summary PnL Real Account Target using challenge cost
    double real_target = g_challenge_cost; // For real account, target is the challenge cost recovery
    string real_target_str = StringFormat("0.00 / %.2f", real_target);
    if(ObjectFind(chart_id, OBJ_SPNL_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_SPNL_REAL, OBJPROP_TEXT, real_target_str);
    }

    // 6) Update Prop Summary PnL Target
    string prop_target_str = StringFormat("0.00 / %.2f", g_stage_target_abs_prop);
    if(ObjectFind(chart_id, OBJ_SPNL_PROP) != -1)
    {
        ObjectSetString(chart_id, OBJ_SPNL_PROP, OBJPROP_TEXT, prop_target_str);
    }

    // 7) Update Daily DD values
    string daily_dd_str = StringFormat("%.2f / %.2f", g_max_daily_dd_abs_prop, g_max_daily_dd_abs_prop);
    if(ObjectFind(chart_id, OBJ_TODDD_PROP) != -1)
    {
        ObjectSetString(chart_id, OBJ_TODDD_PROP, OBJPROP_TEXT, daily_dd_str);
    }

    // 8) Update Max DD values  
    string max_dd_str = StringFormat("%.2f / %.2f", g_max_acc_dd_abs_prop, g_max_acc_dd_abs_prop);
    if(ObjectFind(chart_id, OBJ_MAXDD_PROP) != -1)
    {
        ObjectSetString(chart_id, OBJ_MAXDD_PROP, OBJPROP_TEXT, max_dd_str);
    }

    // 9) Update Prop Account Data
    int acc_login = (int)AccountInfoInteger(ACCOUNT_LOGIN);
    string acc_currency = AccountInfoString(ACCOUNT_CURRENCY);
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    string current_symbol = (symbol != "") ? symbol : _Symbol;

    if(ObjectFind(chart_id, OBJ_ACC_NUM_PROP) != -1)
    {
        ObjectSetString(chart_id, OBJ_ACC_NUM_PROP, OBJPROP_TEXT, IntegerToString(acc_login));
    }
    if(ObjectFind(chart_id, OBJ_CURR_PROP) != -1)
    {
        ObjectSetString(chart_id, OBJ_CURR_PROP, OBJPROP_TEXT, acc_currency);
    }
    if(ObjectFind(chart_id, OBJ_FMGN_PROP) != -1)
    {
        ObjectSetString(chart_id, OBJ_FMGN_PROP, OBJPROP_TEXT, DoubleToString(free_margin, 2));
    }
    if(ObjectFind(chart_id, OBJ_SYM_PROP) != -1)
    {
        ObjectSetString(chart_id, OBJ_SYM_PROP, OBJPROP_TEXT, current_symbol);
    }

    ChartRedraw(chart_id);
}

void Dashboard_UpdateDynamicInfo(double prop_balance,
                                 double prop_equity,
                                 double prop_balance_start_day,
                                 double prop_peak_equity,
                                 int prop_trading_days,
                                 bool session_active,
                                 double master_volume,
                                 double daily_dd_floor_master_ea,
                                 double daily_dd_limit_master_ea_abs,
                                 double static_max_dd_floor_master_ea,
                                 double trailing_max_dd_floor_master_ea,
                                 double max_dd_limit_master_ea_abs)
{
    if(!g_dashboard_initialized) return;
    long chart_id_dyn = ChartID();
    if(chart_id_dyn == 0) return; // Not visible

    g_last_real_account_update_time = TimeCurrent(); // Update the timestamp for Real Account section

    // --- Real Account Updates (Master EA data) ---
    double real_account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
    double real_account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
    // Assuming prop_balance_start_day & prop_peak_equity passed to this function are Master EA's g_prop_balance_at_day_start and g_prop_highest_equity_peak
    // Directly using parameters prop_balance_start_day and prop_peak_equity for real account calculations below

    // Update Real Account Balance display
    if(ObjectFind(chart_id_dyn, OBJ_BALEQ_REAL) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_BALEQ_REAL, OBJPROP_TEXT, DoubleToString(real_account_balance,2) + " (" + DoubleToString(real_account_equity,2) + " Eq)");
    }
    // Update Real Account Last Update Time Remark
    // Note: Last update time is now handled in the proper section below with correct ObjectSetString calls

    // Real Account Today's DD
    double real_actual_daily_loss = prop_balance_start_day - real_account_equity; // Using prop_balance_start_day directly
    if(real_actual_daily_loss < 0) real_actual_daily_loss = 0;
    double real_remaining_daily_dd = daily_dd_limit_master_ea_abs - real_actual_daily_loss;
    if(real_remaining_daily_dd < 0) real_remaining_daily_dd = 0;
    
    string real_daily_dd_str = StringFormat("%.2f / %.2f", real_actual_daily_loss, daily_dd_limit_master_ea_abs);
    if(ObjectFind(chart_id_dyn, OBJ_TODDD_REAL) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_TODDD_REAL, OBJPROP_TEXT, real_daily_dd_str);
        ObjectSetInteger(chart_id_dyn, OBJ_TODDD_REAL, OBJPROP_COLOR, (real_remaining_daily_dd < daily_dd_limit_master_ea_abs * 0.2) ? TextColor_Alert : TextColor_Normal);
    }
    double real_daily_dd_pct_val  = (daily_dd_limit_master_ea_abs > 0.0) ? (real_remaining_daily_dd / daily_dd_limit_master_ea_abs) * 100.0 : 100.0;
    string real_daily_dd_pct_str  = StringFormat("%.1f %% Rem", real_daily_dd_pct_val);
    if(ObjectFind(chart_id_dyn, OBJ_TODDD_REMARKS) != -1) 
    {
        ObjectSetString(chart_id_dyn, OBJ_TODDD_REMARKS, OBJPROP_TEXT, real_daily_dd_pct_str);
    }

    // Real Account Max DD
    // Effective Max DD floor for Real account is the higher of static or trailing floor from EA1
    double effective_max_dd_floor_real = MathMax(static_max_dd_floor_master_ea, trailing_max_dd_floor_master_ea);
    double real_current_drawdown_from_actual_peak = prop_peak_equity - real_account_equity; // Using prop_peak_equity directly
    if(real_current_drawdown_from_actual_peak < 0) real_current_drawdown_from_actual_peak = 0;
    
    double real_remaining_max_dd = real_account_equity - effective_max_dd_floor_real; // How much equity is above the absolute floor
    if(real_remaining_max_dd < 0) real_remaining_max_dd = 0;

    string real_max_dd_str = StringFormat("%.2f / %.2f", real_current_drawdown_from_actual_peak, max_dd_limit_master_ea_abs);
    if(ObjectFind(chart_id_dyn, OBJ_MAXDD_REAL) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_MAXDD_REAL, OBJPROP_TEXT, real_max_dd_str);
        ObjectSetInteger(chart_id_dyn, OBJ_MAXDD_REAL, OBJPROP_COLOR, (real_remaining_max_dd < max_dd_limit_master_ea_abs * 0.2) ? TextColor_Alert : TextColor_Normal);
    }
    double real_max_dd_pct_val  = (max_dd_limit_master_ea_abs > 0.0) ? (real_remaining_max_dd / max_dd_limit_master_ea_abs) * 100.0 : 100.0;
    string real_max_dd_pct_str  = StringFormat("%.1f %% Rem", real_max_dd_pct_val);
    if(ObjectFind(chart_id_dyn, OBJ_MAXDD_REMARKS) != -1) 
    {
        ObjectSetString(chart_id_dyn, OBJ_MAXDD_REMARKS, OBJPROP_TEXT, real_max_dd_pct_str);
    }
    
    // FIXED: Update DD Type field for Real Account
    if(ObjectFind(chart_id_dyn, OBJ_DDTYPE_REAL) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_DDTYPE_REAL, OBJPROP_TEXT, "Balance & Equity");
    }
    
    // FIXED: Update Real Account Trading Days - for now, use same as prop account days since we don't track real account days separately
    // In a full implementation, this would come from the slave EA's trading day tracking
    if(ObjectFind(chart_id_dyn, OBJ_DAYS_REAL) != -1)
    {
        string real_days_str = StringFormat("%d / %d", prop_trading_days, 5); // Use default min days of 5
        color real_days_color = (prop_trading_days >= 5) ? COLOR_TEXT_GREEN : COLOR_TEXT_BLUE;
        ObjectSetString(chart_id_dyn, OBJ_DAYS_REAL, OBJPROP_TEXT, real_days_str);
        ObjectSetInteger(chart_id_dyn, OBJ_DAYS_REAL, OBJPROP_COLOR, real_days_color);
    }
    
    // FIXED: Update Real Account Symbol to match prop account symbol
    if(ObjectFind(chart_id_dyn, OBJ_SYM_REAL) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_SYM_REAL, OBJPROP_TEXT, _Symbol);
    }

    // --- Prop Account Updates (using passed prop_... parameters) ---
    // Update Prop Volume (master_volume is EA1's volume, displayed under Prop column for now as per original design)
    if(ObjectFind(chart_id_dyn, OBJ_VOL_PROP) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_VOL_PROP, OBJPROP_TEXT, DoubleToString(master_volume, 2));
    }

    // Calculate & Update Prop Daily PnL (FIXED: Use equity-based calculation)
    double prop_daily_pnl = prop_equity - prop_balance_start_day;  // Fixed: parameter name represents equity at day start
    color pnl_color = (prop_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    string daily_pnl_str = DoubleToString(prop_daily_pnl, 2);

    if(ObjectFind(chart_id_dyn, OBJ_DPNL_PROP) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_DPNL_PROP, OBJPROP_TEXT, daily_pnl_str);
        ObjectSetInteger(chart_id_dyn, OBJ_DPNL_PROP, OBJPROP_COLOR, pnl_color);
    }

    // 4) Update Prop Summary PnL and Progress
    // Get the stored static values from Dashboard_UpdateStaticInfo
    static double _cached_stage_target_abs = 0.0;
    static double _cached_daily_dd_abs = 0.0;
    static double _cached_max_dd_abs = 0.0;
    static int _cached_min_days = 0;
    
    // Initialize with passed parameters on first call
    if(_cached_stage_target_abs == 0.0) 
    {
        _cached_stage_target_abs = daily_dd_limit_master_ea_abs; // Use actual target from calculations
        _cached_daily_dd_abs = daily_dd_limit_master_ea_abs;
        _cached_max_dd_abs = max_dd_limit_master_ea_abs;
        _cached_min_days = 5; // Default minimum days
    }
    
    double summary_pnl_value = prop_equity - prop_balance_start_day;  // Fixed: parameter represents equity at day start
    string summary_pnl_str = StringFormat("%.2f / %.2f", summary_pnl_value, _cached_stage_target_abs);

    if(ObjectFind(chart_id_dyn, OBJ_SPNL_PROP) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_SPNL_PROP, OBJPROP_TEXT, summary_pnl_str);
    }

    // 5) Progress Percentage
    double progress_pct = (_cached_stage_target_abs > 0.0)
                          ? ( (prop_equity - prop_balance_start_day) / _cached_stage_target_abs ) * 100.0  // Fixed: parameter represents equity at day start
                          : 0.0;
    string progress_str = StringFormat("%.1f %% / 100.0 %%", progress_pct);

    if(ObjectFind(chart_id_dyn, OBJ_SPNL_REMARKS) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_SPNL_REMARKS, OBJPROP_TEXT, progress_str);
    }

    // 6) Trading Days (color green if >= min_days)
    string days_str = StringFormat("%d / %d", prop_trading_days, _cached_min_days);
    color days_color = (prop_trading_days >= _cached_min_days) ? COLOR_TEXT_GREEN : COLOR_TEXT_BLUE;

    if(ObjectFind(chart_id_dyn, OBJ_DAYS_PROP) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_DAYS_PROP, OBJPROP_TEXT, days_str);
        ObjectSetInteger(chart_id_dyn, OBJ_DAYS_PROP, OBJPROP_COLOR, days_color);
    }

    // 7) Update Account Balance & Equity
    if(ObjectFind(chart_id_dyn, OBJ_BALEQ_PROP) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_BALEQ_PROP, OBJPROP_TEXT, DoubleToString(prop_equity, 2));
    }

    // 8) DAILY DD Calculation & Update
    double actual_daily_loss = prop_balance_start_day - prop_equity;  // Fixed: parameter represents equity at day start
    if(actual_daily_loss < 0) actual_daily_loss = 0;
    double remaining_daily_dd = daily_dd_limit_master_ea_abs - actual_daily_loss;
    if(remaining_daily_dd < 0) remaining_daily_dd = 0;
    string daily_dd_str      = StringFormat("%.2f / %.2f", daily_dd_limit_master_ea_abs, remaining_daily_dd);
    double daily_dd_pct_val  = (daily_dd_limit_master_ea_abs > 0.0) ? (remaining_daily_dd / daily_dd_limit_master_ea_abs) * 100.0 : 100.0;
    string daily_dd_pct_str  = StringFormat("%.1f %%", daily_dd_pct_val);

    if(ObjectFind(chart_id_dyn, OBJ_TODDD_PROP) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_TODDD_PROP, OBJPROP_TEXT, daily_dd_str);
    }
    if(ObjectFind(chart_id_dyn, OBJ_TODDD_REMARKS) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_TODDD_REMARKS, OBJPROP_TEXT, daily_dd_pct_str);
    }

    // 9) MAX DD Calculation & Update
    double current_drawdown = prop_peak_equity - prop_equity;
    if(current_drawdown < 0) current_drawdown = 0;
    double remaining_max_dd = max_dd_limit_master_ea_abs - current_drawdown;
    if(remaining_max_dd < 0) remaining_max_dd = 0;
    string max_dd_str      = StringFormat("%.2f / %.2f", max_dd_limit_master_ea_abs, remaining_max_dd);
    double max_dd_pct_val  = (max_dd_limit_master_ea_abs > 0.0) ? (remaining_max_dd / max_dd_limit_master_ea_abs) * 100.0 : 100.0;
    string max_dd_pct_str  = StringFormat("%.1f %%", max_dd_pct_val);

    if(ObjectFind(chart_id_dyn, OBJ_MAXDD_PROP) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_MAXDD_PROP, OBJPROP_TEXT, max_dd_str);
    }
    if(ObjectFind(chart_id_dyn, OBJ_MAXDD_REMARKS) != -1)
    {
        ObjectSetString(chart_id_dyn, OBJ_MAXDD_REMARKS, OBJPROP_TEXT, max_dd_pct_str);
    }

    // 7) Update Balance/Equity Remarks with last update time
    if(ObjectFind(chart_id_dyn, OBJ_BALEQ_REMARKS) != -1)
    {
        string last_upd_str = StringFormat("Last Upd: %s", TimeToString(g_last_real_account_update_time, TIME_DATE|TIME_MINUTES));
        ObjectSetString(chart_id_dyn, OBJ_BALEQ_REMARKS, OBJPROP_TEXT, last_upd_str);
        ObjectSetInteger(chart_id_dyn, OBJ_BALEQ_REMARKS, OBJPROP_FONTSIZE, 8);
        ObjectSetString(chart_id_dyn, OBJ_BALEQ_REMARKS, OBJPROP_FONT, "Arial");
        ObjectSetInteger(chart_id_dyn, OBJ_BALEQ_REMARKS, OBJPROP_COLOR, COLOR_TEXT_BLACK);
    }

    ChartRedraw(chart_id_dyn);
}

void Dashboard_UpdateStatus(string status_text, bool is_signal_active)
{
    long chart_id = ChartID();

    if(ObjectFind(chart_id, OBJ_STATUS_VALUE) != -1)
    {
        ObjectSetString(chart_id, OBJ_STATUS_VALUE, OBJPROP_TEXT, status_text);
        // Color logic: if "LONG" + active → green, if "SHORT" + active → red, else black
        color col = COLOR_TEXT_BLACK;
        if(is_signal_active && StringFind(status_text, "LONG") != -1)  col = COLOR_TEXT_GREEN;
        else if(is_signal_active && StringFind(status_text, "SHORT") != -1) col = COLOR_TEXT_RED;
        ObjectSetInteger(chart_id, OBJ_STATUS_VALUE, OBJPROP_COLOR, col);
    }
    ChartRedraw(chart_id);
}

void Dashboard_UpdateSlaveStatus(string slave_status_str,
                                 double slave_balance,
                                 double slave_equity,
                                 double slave_daily_pnl,
                                 bool slave_connected,
                                 double hedge_pnl = 0.0,
                                 double hedge_loss_percentage = 0.0,
                                 double challenge_cost = 700.0)
{
    long chart_id = ChartID();

    // 1) Extract Slave Volume (search for "Vol=")
    double slave_vol = 0.0;
    int posVol = StringFind(slave_status_str, "Vol=");
    if(posVol != -1)
    {
        int start = posVol + 4;
        int end   = StringFind(slave_status_str, ",", start);
        if(end == -1) end = StringFind(slave_status_str, " ", start);
        if(end > start)
            slave_vol = StringToDouble(StringSubstr(slave_status_str, start, end - start));
    }
    if(ObjectFind(chart_id, OBJ_VOL_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_VOL_REAL, OBJPROP_TEXT, DoubleToString(slave_vol, 2));
    }

    // 2) Update Real Daily PnL
    color real_pnl_col = (slave_daily_pnl >= 0.0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    string real_daily_pnl_str = DoubleToString(slave_daily_pnl, 2);
    if(ObjectFind(chart_id, OBJ_DPNL_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_DPNL_REAL, OBJPROP_TEXT, real_daily_pnl_str);
        ObjectSetInteger(chart_id, OBJ_DPNL_REAL, OBJPROP_COLOR, real_pnl_col);
    }

    // 2.5) Update Hedge Loss Display
    string hedge_display = "N/A";
    color hedge_color = COLOR_TEXT_BLACK;
    string hedge_remarks = "No Position";
    
    if(slave_vol > 0.0) // Only show hedge data if there's a hedge position
    {
        hedge_display = StringFormat("$%.2f (%.1f%%)", hedge_pnl, hedge_loss_percentage);
        
        // Color based on loss level
        if(hedge_pnl >= 0.0)
        {
            hedge_color = COLOR_TEXT_GREEN;
            hedge_remarks = "Profit";
        }
        else if(hedge_loss_percentage < 15.0) // Less than low threshold
        {
            hedge_color = COLOR_TEXT_GREEN;
            hedge_remarks = "Low Loss";
        }
        else if(hedge_loss_percentage < 50.0) // Between low and high threshold
        {
            hedge_color = COLOR_TEXT_ORANGE; // Orange
            hedge_remarks = "Med Loss";
        }
        else // High loss
        {
            hedge_color = COLOR_TEXT_RED;
            hedge_remarks = "High Loss";
        }
    }
    
    if(ObjectFind(chart_id, OBJ_HEDGE_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_HEDGE_REAL, OBJPROP_TEXT, hedge_display);
        ObjectSetInteger(chart_id, OBJ_HEDGE_REAL, OBJPROP_COLOR, hedge_color);
    }
    if(ObjectFind(chart_id, OBJ_HEDGE_REMARKS) != -1)
    {
        ObjectSetString(chart_id, OBJ_HEDGE_REMARKS, OBJPROP_TEXT, hedge_remarks);
        ObjectSetInteger(chart_id, OBJ_HEDGE_REMARKS, OBJPROP_COLOR, hedge_color);
    }

    // 3) Extract real account number "AccNum=" and currency "Curr="
    string real_acc_num = "Unknown";
    string real_acc_curr = "Unknown";
    int posAcc = StringFind(slave_status_str, "AccNum=");
    if(posAcc != -1)
    {
        int start = posAcc + 7;
        int end   = StringFind(slave_status_str, ",", start);
        if(end == -1) end = StringFind(slave_status_str, " ", start);
        if(end > start)
            real_acc_num = StringSubstr(slave_status_str, start, end - start);
    }
    int posCurr = StringFind(slave_status_str, "Curr=");
    if(posCurr != -1)
    {
        int start = posCurr + 5;
        int end   = StringFind(slave_status_str, ",", start);
        if(end == -1) end = StringFind(slave_status_str, " ", start);
        if(end > start)
            real_acc_curr = StringSubstr(slave_status_str, start, end - start);
    }
    // Estimate free margin as 90% of slave_balance (simple placeholder)
    double est_free_margin = slave_balance * 0.90;

    // --- Update Summary PnL for Real Account (challenge cost recovery target) ---
    double real_total_pnl = slave_equity - slave_balance;
    string real_summary_pnl = StringFormat("%.2f / %.2f", real_total_pnl, challenge_cost);
    color real_summary_col = (real_total_pnl >= 0.0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    
    if(ObjectFind(chart_id, OBJ_SPNL_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_SPNL_REAL, OBJPROP_TEXT, real_summary_pnl);
        ObjectSetInteger(chart_id, OBJ_SPNL_REAL, OBJPROP_COLOR, real_summary_col);
    }

    // --- Update Summary PnL Progress for Real Account ---
    double real_progress_pct = (challenge_cost > 0.0) ? (real_total_pnl / challenge_cost) * 100.0 : 0.0;
    string real_progress_str = StringFormat("%.1f %% / 100.0 %%", real_progress_pct);
    
    if(ObjectFind(chart_id, OBJ_SPNL_REMARKS) != -1)
    {
        ObjectSetString(chart_id, OBJ_SPNL_REMARKS, OBJPROP_TEXT, real_progress_str);
    }

    if(ObjectFind(chart_id, OBJ_ACC_NUM_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_ACC_NUM_REAL, OBJPROP_TEXT, real_acc_num);
    }
    if(ObjectFind(chart_id, OBJ_CURR_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_CURR_REAL, OBJPROP_TEXT, real_acc_curr);
    }
    if(ObjectFind(chart_id, OBJ_FMGN_REAL) != -1)
    {
        ObjectSetString(chart_id, OBJ_FMGN_REAL, OBJPROP_TEXT, DoubleToString(est_free_margin, 2));
    }

    // --- Connection Status & Currency Matching ---
    string conn_status = slave_connected ? "Connected" : "Disconnected";
    color conn_color = slave_connected ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    
    if(ObjectFind(chart_id, OBJ_ACC_NUM_REMARKS) != -1)
    {
        ObjectSetString(chart_id, OBJ_ACC_NUM_REMARKS, OBJPROP_TEXT, conn_status);
        ObjectSetInteger(chart_id, OBJ_ACC_NUM_REMARKS, OBJPROP_COLOR, conn_color);
    }

    // Check currency match between prop and real accounts
    string prop_curr = AccountInfoString(ACCOUNT_CURRENCY);
    string currency_match = "N/A";
    color match_col = COLOR_TEXT_BLACK;
    
    if(real_acc_curr != "Unknown" && prop_curr != "")
    {
        if(real_acc_curr == prop_curr)
        {
            currency_match = "Match";
            match_col = COLOR_TEXT_GREEN;
        }
        else
        {
            currency_match = "Mismatch";
            match_col = COLOR_TEXT_RED;
        }
    }
    if(ObjectFind(chart_id, OBJ_CURR_REMARKS) != -1)
    {
        ObjectSetString(chart_id, OBJ_CURR_REMARKS, OBJPROP_TEXT, currency_match);
        ObjectSetInteger(chart_id, OBJ_CURR_REMARKS, OBJPROP_COLOR, match_col);
    }

    ChartRedraw(chart_id);
}

//+------------------------------------------------------------------+
//| Cost Recovery Update Function - MISSING FUNCTIONALITY RESTORED  |
//+------------------------------------------------------------------+
void Dashboard_UpdateCostRecovery(double prop_balance_start_day,
                                  double prop_equity,
                                  double prop_peak_equity,
                                  double daily_dd_limit_abs,
                                  double max_dd_limit_abs,
                                  double real_equity,
                                  double real_balance,
                                  double challenge_cost)
{
    if(!g_dashboard_initialized) return;
    long chart_id = ChartID();

    // === DAILY DD COST RECOVERY CALCULATION ===
    
    // Calculate actual daily loss on prop account
    double daily_loss_prop = 0.0;
    if(prop_balance_start_day > prop_equity)
    {
        daily_loss_prop = prop_balance_start_day - prop_equity;
    }
    
    // Calculate profit/loss on real account (hedge)
    double real_pnl = real_equity - real_balance;
    
    // Calculate recovery percentage for daily DD
    double daily_recovery_pct = 0.0;
    if(daily_loss_prop > 0.0)
    {
        daily_recovery_pct = (real_pnl / daily_loss_prop) * 100.0;
        if(daily_recovery_pct < 0.0) daily_recovery_pct = 0.0; // Don't show negative recovery
    }
    
    // Update Daily DD Cost Recovery Row
    string daily_loss_str = (daily_loss_prop > 0.0) ? StringFormat("-%.2f", daily_loss_prop) : "0.00";
    string daily_profit_str = (real_pnl >= 0.0) ? StringFormat("%.2f", real_pnl) : StringFormat("%.2f", real_pnl);
    string daily_recovery_str = StringFormat("%.1f %%", daily_recovery_pct);
    
    color daily_loss_color = (daily_loss_prop > 0.0) ? COLOR_TEXT_RED : COLOR_TEXT_BLACK;
    color daily_profit_color = (real_pnl >= 0.0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    color daily_recovery_color = COLOR_TEXT_BLACK;
    if(daily_recovery_pct >= 80.0) daily_recovery_color = COLOR_TEXT_GREEN;
    else if(daily_recovery_pct >= 50.0) daily_recovery_color = COLOR_TEXT_ORANGE;
    else if(daily_recovery_pct > 0.0) daily_recovery_color = COLOR_TEXT_RED;
    
    if(ObjectFind(chart_id, OBJ_CR_DDD_LOSS) != -1)
    {
        ObjectSetString(chart_id, OBJ_CR_DDD_LOSS, OBJPROP_TEXT, daily_loss_str);
        ObjectSetInteger(chart_id, OBJ_CR_DDD_LOSS, OBJPROP_COLOR, daily_loss_color);
    }
    if(ObjectFind(chart_id, OBJ_CR_DDD_PROFIT) != -1)
    {
        ObjectSetString(chart_id, OBJ_CR_DDD_PROFIT, OBJPROP_TEXT, daily_profit_str);
        ObjectSetInteger(chart_id, OBJ_CR_DDD_PROFIT, OBJPROP_COLOR, daily_profit_color);
    }
    if(ObjectFind(chart_id, OBJ_CR_DDD_RECOVERY) != -1)
    {
        ObjectSetString(chart_id, OBJ_CR_DDD_RECOVERY, OBJPROP_TEXT, daily_recovery_str);
        ObjectSetInteger(chart_id, OBJ_CR_DDD_RECOVERY, OBJPROP_COLOR, daily_recovery_color);
    }

    // === MAX DD COST RECOVERY CALCULATION ===
    
    // Calculate maximum drawdown loss on prop account
    double max_dd_loss_prop = 0.0;
    if(prop_peak_equity > prop_equity)
    {
        max_dd_loss_prop = prop_peak_equity - prop_equity;
    }
    
    // Calculate recovery percentage for max DD
    double max_dd_recovery_pct = 0.0;
    if(max_dd_loss_prop > 0.0)
    {
        max_dd_recovery_pct = (real_pnl / max_dd_loss_prop) * 100.0;
        if(max_dd_recovery_pct < 0.0) max_dd_recovery_pct = 0.0; // Don't show negative recovery
    }
    
    // Update Max DD Cost Recovery Row
    string max_dd_loss_str = (max_dd_loss_prop > 0.0) ? StringFormat("-%.2f", max_dd_loss_prop) : "0.00";
    string max_dd_profit_str = (real_pnl >= 0.0) ? StringFormat("%.2f", real_pnl) : StringFormat("%.2f", real_pnl);
    string max_dd_recovery_str = StringFormat("%.1f %%", max_dd_recovery_pct);
    
    color max_dd_loss_color = (max_dd_loss_prop > 0.0) ? COLOR_TEXT_RED : COLOR_TEXT_BLACK;
    color max_dd_profit_color = (real_pnl >= 0.0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
    color max_dd_recovery_color = COLOR_TEXT_BLACK;
    if(max_dd_recovery_pct >= 80.0) max_dd_recovery_color = COLOR_TEXT_GREEN;
    else if(max_dd_recovery_pct >= 50.0) max_dd_recovery_color = COLOR_TEXT_ORANGE;
    else if(max_dd_recovery_pct > 0.0) max_dd_recovery_color = COLOR_TEXT_RED;
    
    if(ObjectFind(chart_id, OBJ_CR_MDD_LOSS) != -1)
    {
        ObjectSetString(chart_id, OBJ_CR_MDD_LOSS, OBJPROP_TEXT, max_dd_loss_str);
        ObjectSetInteger(chart_id, OBJ_CR_MDD_LOSS, OBJPROP_COLOR, max_dd_loss_color);
    }
    if(ObjectFind(chart_id, OBJ_CR_MDD_PROFIT) != -1)
    {
        ObjectSetString(chart_id, OBJ_CR_MDD_PROFIT, OBJPROP_TEXT, max_dd_profit_str);
        ObjectSetInteger(chart_id, OBJ_CR_MDD_PROFIT, OBJPROP_COLOR, max_dd_profit_color);
    }
    if(ObjectFind(chart_id, OBJ_CR_MDD_RECOVERY) != -1)
    {
        ObjectSetString(chart_id, OBJ_CR_MDD_RECOVERY, OBJPROP_TEXT, max_dd_recovery_str);
        ObjectSetInteger(chart_id, OBJ_CR_MDD_RECOVERY, OBJPROP_COLOR, max_dd_recovery_color);
    }

    ChartRedraw(chart_id);
}

// --- OPTIONAL: Validation Utility (checks for existence of key objects) ---
bool Dashboard_ValidateInitialization()
{
    long chart_id = ChartID();
    bool success = true;
    int missing = 0;

    string keys[] =
    {
        OBJ_TIMESTAMP_LABEL,
        OBJ_STATUS_VALUE,
        OBJ_WMODE_VALUE,
        OBJ_VOL_PROP,
        OBJ_DPNL_PROP,
        OBJ_SPNL_PROP,
        OBJ_ACC_NUM_PROP,
        OBJ_CURR_PROP,
        OBJ_BALEQ_PROP
    };

    for(int i = 0; i < ArraySize(keys); i++)
    {
        if(ObjectFind(chart_id, keys[i]) == -1)
        {
            missing++;
            success = false;
        }
    }

    int total_objs = ObjectsTotal(chart_id);
    if(!success)
        Print("WARNING: Dashboard missing key objects!");
    else
        Print("Dashboard validation PASSED.");

    return success;
}

// --- CHART VISUALS FUNCTIONS ---
// These functions handle pivot and market bias visual elements on the chart

void ChartVisuals_InitPivots(bool show_pivots, color up_color, color down_color)
{
    if(show_pivots)
    {
        // Initialization logic for pivot visuals can be added here if needed
    }
}

void ChartVisuals_InitMarketBias(bool show_bias, color up_color, color down_color)
{
    if(show_bias)
    {
        // Initialization logic for market bias visuals can be added here if needed
    }
}

void ChartVisuals_DeinitPivots()
{
    ObjectsDeleteAll(ChartID(), "PivotHighLine_");
    ObjectsDeleteAll(ChartID(), "PivotLowLine_"); 
}

void ChartVisuals_DeinitMarketBias()
{
    ObjectsDeleteAll(ChartID(), "MarketBias_");
}

void ChartVisuals_UpdatePivots(PivotPoint &high_pivots[], PivotPoint &low_pivots[], bool show_pivots, color up_color, color down_color)
{
    if(!show_pivots) return;
    
    long chart_id = ChartID();
    
    // Remove any existing pivot objects from previous draw
    ObjectsDeleteAll(chart_id, "PivotHighLine_"); // Prefix for high pivot lines
    ObjectsDeleteAll(chart_id, "PivotLowLine_");  // Prefix for low pivot lines
    ObjectsDeleteAll(chart_id, "PivotZZ_");       // Remove old zigzag lines if any
    ObjectsDeleteAll(chart_id, "PivotHigh_");     // Remove old arrow objects if any
    ObjectsDeleteAll(chart_id, "PivotLow_");      // Remove old arrow objects if any

    // Draw trend line connecting high pivots
    int totalHigh = ArraySize(high_pivots);
    if(totalHigh >= 2)
    {
        // Sort high_pivots by time ascending to ensure lines are drawn chronologically
        for(int i = 0; i < totalHigh - 1; i++)
        {
            for(int j = i + 1; j < totalHigh; j++)
            {
                if(high_pivots[i].time > high_pivots[j].time)
                {
                    PivotPoint temp = high_pivots[i];
                    high_pivots[i] = high_pivots[j];
                    high_pivots[j] = temp;
                }
            }
        }

        for(int i = 0; i < totalHigh - 1; i++)
        {
            datetime t1 = high_pivots[i].time;
            double   p1 = high_pivots[i].price;
            datetime t2 = high_pivots[i+1].time;
            double   p2 = high_pivots[i+1].price;

            if(t1 <= 0 || t2 <= 0 || p1 <= 0 || p2 <= 0 || t1 >= t2) continue;

            string obj_name = StringFormat("PivotHighLine_%d", i);
            if(ObjectCreate(chart_id, obj_name, OBJ_TREND, 0, t1, p1, t2, p2))
            {
                ObjectSetInteger(chart_id, obj_name, OBJPROP_COLOR, up_color);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_WIDTH, 2);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_RAY, false);
            }
        }
    }

    // Draw trend line connecting low pivots
    int totalLow = ArraySize(low_pivots);
    if(totalLow >= 2)
    {
        // Sort low_pivots by time ascending
        for(int i = 0; i < totalLow - 1; i++)
        {
            for(int j = i + 1; j < totalLow; j++)
            {
                if(low_pivots[i].time > low_pivots[j].time)
                {
                    PivotPoint temp = low_pivots[i];
                    low_pivots[i] = low_pivots[j];
                    low_pivots[j] = temp;
                }
            }
        }

        for(int i = 0; i < totalLow - 1; i++)
        {
            datetime t1 = low_pivots[i].time;
            double   p1 = low_pivots[i].price;
            datetime t2 = low_pivots[i+1].time;
            double   p2 = low_pivots[i+1].price;

            if(t1 <= 0 || t2 <= 0 || p1 <= 0 || p2 <= 0 || t1 >= t2) continue;

            string obj_name = StringFormat("PivotLowLine_%d", i);
            if(ObjectCreate(chart_id, obj_name, OBJ_TREND, 0, t1, p1, t2, p2))
            {
                ObjectSetInteger(chart_id, obj_name, OBJPROP_COLOR, down_color);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_WIDTH, 2);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_STYLE, STYLE_SOLID);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_SELECTABLE, false);
                ObjectSetInteger(chart_id, obj_name, OBJPROP_RAY, false);
            }
        }
    }
}

void ChartVisuals_UpdateMarketBias(double bias_value, bool show_bias)
{
    if(!show_bias) return;
    
    long chart_id = ChartID();
    string obj_name = "MarketBias_Indicator";
    
    // Clean up existing market bias object
    ObjectDelete(chart_id, obj_name);
    
    if(ObjectCreate(chart_id, obj_name, OBJ_LABEL, 0, 0, 0))
    {
        string bias_text = StringFormat("Market Bias: %.4f %s", bias_value, 
                                      bias_value > 0 ? "(Bullish)" : bias_value < 0 ? "(Bearish)" : "(Neutral)");
        color bias_color = bias_value > 0 ? COLOR_TEXT_GREEN : bias_value < 0 ? COLOR_TEXT_RED : COLOR_TEXT_BLACK;
        
        ObjectSetString(chart_id, obj_name, OBJPROP_TEXT, bias_text);
        ObjectSetInteger(chart_id, obj_name, OBJPROP_XDISTANCE, 10);
        ObjectSetInteger(chart_id, obj_name, OBJPROP_YDISTANCE, 200);
        ObjectSetInteger(chart_id, obj_name, OBJPROP_COLOR, bias_color);
        ObjectSetInteger(chart_id, obj_name, OBJPROP_FONTSIZE, 10);
        ObjectSetString(chart_id, obj_name, OBJPROP_FONT, "Arial");
        ObjectSetInteger(chart_id, obj_name, OBJPROP_SELECTABLE, false);
    }
}

//+------------------------------------------------------------------+
//| Update Daily PnL Breakdown Section                              |
//+------------------------------------------------------------------+
void Dashboard_UpdateDailyPnL(double prop_total_daily_pnl,
                               double prop_realized_daily_pnl,
                               double prop_unrealized_daily_pnl,
                               double real_total_daily_pnl,
                               double real_realized_daily_pnl,
                               double real_unrealized_daily_pnl)
{
    if(!g_dashboard_initialized) return;
    long chart_id = ChartID();
    if(chart_id == 0) return;

    // Update Prop Account Daily PnL values
    if(ObjectFind(chart_id, OBJ_DPNL_TOTAL_PROP) != -1)
    {
        color total_color = (prop_total_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_DPNL_TOTAL_PROP, OBJPROP_TEXT, DoubleToString(prop_total_daily_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_DPNL_TOTAL_PROP, OBJPROP_COLOR, total_color);
    }
    
    if(ObjectFind(chart_id, OBJ_DPNL_REALIZED_PROP) != -1)
    {
        color realized_color = (prop_realized_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_DPNL_REALIZED_PROP, OBJPROP_TEXT, DoubleToString(prop_realized_daily_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_DPNL_REALIZED_PROP, OBJPROP_COLOR, realized_color);
    }
    
    if(ObjectFind(chart_id, OBJ_DPNL_UNREALIZED_PROP) != -1)
    {
        color unrealized_color = (prop_unrealized_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_DPNL_UNREALIZED_PROP, OBJPROP_TEXT, DoubleToString(prop_unrealized_daily_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_DPNL_UNREALIZED_PROP, OBJPROP_COLOR, unrealized_color);
    }

    // Update Real Account Daily PnL values
    if(ObjectFind(chart_id, OBJ_DPNL_TOTAL_REAL) != -1)
    {
        color total_color = (real_total_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_DPNL_TOTAL_REAL, OBJPROP_TEXT, DoubleToString(real_total_daily_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_DPNL_TOTAL_REAL, OBJPROP_COLOR, total_color);
    }
    
    if(ObjectFind(chart_id, OBJ_DPNL_REALIZED_REAL) != -1)
    {
        color realized_color = (real_realized_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_DPNL_REALIZED_REAL, OBJPROP_TEXT, DoubleToString(real_realized_daily_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_DPNL_REALIZED_REAL, OBJPROP_COLOR, realized_color);
    }
    
    if(ObjectFind(chart_id, OBJ_DPNL_UNREALIZED_REAL) != -1)
    {
        color unrealized_color = (real_unrealized_daily_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_DPNL_UNREALIZED_REAL, OBJPROP_TEXT, DoubleToString(real_unrealized_daily_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_DPNL_UNREALIZED_REAL, OBJPROP_COLOR, unrealized_color);
    }

    // Update status remarks
    string status_text = "Live";
    if(prop_total_daily_pnl == 0.0 && real_total_daily_pnl == 0.0)
        status_text = "No Activity";
    else if(MathAbs(prop_total_daily_pnl) < 0.01 && MathAbs(real_total_daily_pnl) < 0.01)
        status_text = "Minimal";
    
    if(ObjectFind(chart_id, OBJ_DPNL_TOTAL_REMARKS) != -1)
    {
        ObjectSetString(chart_id, OBJ_DPNL_TOTAL_REMARKS, OBJPROP_TEXT, status_text);
    }

    ChartRedraw(chart_id);
}

//+------------------------------------------------------------------+
//| Update Cumulative PnL Tracking Section                          |
//+------------------------------------------------------------------+
void Dashboard_UpdateCumulativePnL(double prop_cumulative_pnl,
                                    double prop_max_drawdown_pct,
                                    double prop_annualized_return_pct,
                                    double real_cumulative_pnl,
                                    double real_max_drawdown_pct,
                                    double real_annualized_return_pct,
                                    int trading_days_total)
{
    if(!g_dashboard_initialized) return;
    long chart_id = ChartID();
    if(chart_id == 0) return;

    // Update Prop Account Cumulative PnL values
    if(ObjectFind(chart_id, OBJ_CPNL_TOTAL_PROP) != -1)
    {
        color total_color = (prop_cumulative_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_CPNL_TOTAL_PROP, OBJPROP_TEXT, DoubleToString(prop_cumulative_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_CPNL_TOTAL_PROP, OBJPROP_COLOR, total_color);
    }
    
    if(ObjectFind(chart_id, OBJ_CPNL_DRAWDOWN_PROP) != -1)
    {
        color dd_color = (prop_max_drawdown_pct <= -10.0) ? COLOR_TEXT_RED : COLOR_TEXT_ORANGE;
        if(prop_max_drawdown_pct >= -5.0) dd_color = COLOR_TEXT_GREEN;
        ObjectSetString(chart_id, OBJ_CPNL_DRAWDOWN_PROP, OBJPROP_TEXT, DoubleToString(prop_max_drawdown_pct, 2) + "%");
        ObjectSetInteger(chart_id, OBJ_CPNL_DRAWDOWN_PROP, OBJPROP_COLOR, dd_color);
    }
    
    if(ObjectFind(chart_id, OBJ_CPNL_RETURN_PROP) != -1)
    {
        color return_color = (prop_annualized_return_pct >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_CPNL_RETURN_PROP, OBJPROP_TEXT, DoubleToString(prop_annualized_return_pct, 2) + "%");
        ObjectSetInteger(chart_id, OBJ_CPNL_RETURN_PROP, OBJPROP_COLOR, return_color);
    }

    // Update Real Account Cumulative PnL values
    if(ObjectFind(chart_id, OBJ_CPNL_TOTAL_REAL) != -1)
    {
        color total_color = (real_cumulative_pnl >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_CPNL_TOTAL_REAL, OBJPROP_TEXT, DoubleToString(real_cumulative_pnl, 2));
        ObjectSetInteger(chart_id, OBJ_CPNL_TOTAL_REAL, OBJPROP_COLOR, total_color);
    }
    
    if(ObjectFind(chart_id, OBJ_CPNL_DRAWDOWN_REAL) != -1)
    {
        color dd_color = (real_max_drawdown_pct <= -10.0) ? COLOR_TEXT_RED : COLOR_TEXT_ORANGE;
        if(real_max_drawdown_pct >= -5.0) dd_color = COLOR_TEXT_GREEN;
        ObjectSetString(chart_id, OBJ_CPNL_DRAWDOWN_REAL, OBJPROP_TEXT, DoubleToString(real_max_drawdown_pct, 2) + "%");
        ObjectSetInteger(chart_id, OBJ_CPNL_DRAWDOWN_REAL, OBJPROP_COLOR, dd_color);
    }
    
    if(ObjectFind(chart_id, OBJ_CPNL_RETURN_REAL) != -1)
    {
        color return_color = (real_annualized_return_pct >= 0) ? COLOR_TEXT_GREEN : COLOR_TEXT_RED;
        ObjectSetString(chart_id, OBJ_CPNL_RETURN_REAL, OBJPROP_TEXT, DoubleToString(real_annualized_return_pct, 2) + "%");
        ObjectSetInteger(chart_id, OBJ_CPNL_RETURN_REAL, OBJPROP_COLOR, return_color);
    }

    // Update performance remarks
    string performance_text = StringFormat("%d Days", trading_days_total);
    if(trading_days_total < 7)
        performance_text = "New";
    else if(prop_annualized_return_pct > 15.0)
        performance_text = "Excellent";
    else if(prop_annualized_return_pct > 5.0)
        performance_text = "Good";
    else if(prop_annualized_return_pct > -5.0)
        performance_text = "Fair";
    else
        performance_text = "Poor";
    
    if(ObjectFind(chart_id, OBJ_CPNL_TOTAL_REMARKS) != -1)
    {
        ObjectSetString(chart_id, OBJ_CPNL_TOTAL_REMARKS, OBJPROP_TEXT, performance_text);
    }

    ChartRedraw(chart_id);
}

//+------------------------------------------------------------------+
//| Create Drawdown Dashboard                                        |
//+------------------------------------------------------------------+
void CreateDrawdownDashboard(long chart_id, int start_y)
{
    // Constants for drawdown dashboard
    const int DD_BAR_WIDTH = 160;
    const int DD_BAR_HEIGHT = 8;
    const int DD_PANEL_WIDTH = DD_BAR_WIDTH + 2 * 20; // 20 is the offset
    const int DD_PANEL_HEIGHT = 90;
    
    int curX = DASH_START_X;
    int curY = start_y;

    // Panel background
    CreateRectangle(chart_id, OBJ_DD_PANEL_BG, curX, curY, DD_PANEL_WIDTH, DD_PANEL_HEIGHT, clrDarkGray);
    
    // Daily drawdown label
    CreateText(chart_id, OBJ_DD_DAILY_LABEL, "Daily DD: 0.00% (Limit: 5.00%)",
               curX + 20, curY + 20, COLOR_TEXT_WHITE, 9, TEXT_FONT_STD, ANCHOR_LEFT);
    
    // Daily bar background
    CreateRectangle(chart_id, OBJ_DD_DAILY_BAR_BACK, curX + 20, curY + 40, DD_BAR_WIDTH, DD_BAR_HEIGHT, clrSilver);
    
    // Daily bar fill
    CreateRectangle(chart_id, OBJ_DD_DAILY_BAR_FILL, curX + 20, curY + 40, 0, DD_BAR_HEIGHT, clrRed);
    
    // Max drawdown label
    CreateText(chart_id, OBJ_DD_MAX_LABEL, "Max DD: 0.00% (Limit: 10.00%)",
               curX + 20, curY + 60, COLOR_TEXT_WHITE, 9, TEXT_FONT_STD, ANCHOR_LEFT);
    
    // Max bar background
    CreateRectangle(chart_id, OBJ_DD_MAX_BAR_BACK, curX + 20, curY + 80, DD_BAR_WIDTH, DD_BAR_HEIGHT, clrSilver);
    
    // Max bar fill
    CreateRectangle(chart_id, OBJ_DD_MAX_BAR_FILL, curX + 20, curY + 80, 0, DD_BAR_HEIGHT, clrRed);
}

//+------------------------------------------------------------------+
//| Update Drawdown Dashboard                                        |
//+------------------------------------------------------------------+
void Dashboard_UpdateDrawdown(double daily_dd_pct, double max_dd_pct, double daily_limit_pct, double max_limit_pct)
{
    if(!g_dashboard_initialized) return;
    long chart_id = ChartID();
    if(chart_id == 0) return;

    // Constants for drawdown dashboard
    const int DD_BAR_WIDTH = 160;
    
    // Update daily drawdown text and bar
    string daily_text = StringFormat("Daily DD: %.2f%% (Limit: %.2f%%)", daily_dd_pct, daily_limit_pct);
    if(ObjectFind(chart_id, OBJ_DD_DAILY_LABEL) != -1)
    {
        ObjectSetString(chart_id, OBJ_DD_DAILY_LABEL, OBJPROP_TEXT, daily_text);
    }
    
    // Update daily bar fill
    if(ObjectFind(chart_id, OBJ_DD_DAILY_BAR_FILL) != -1)
    {
        int daily_fill_width = (int)MathMin(DD_BAR_WIDTH, DD_BAR_WIDTH * daily_dd_pct / daily_limit_pct);
        ObjectSetInteger(chart_id, OBJ_DD_DAILY_BAR_FILL, OBJPROP_XSIZE, daily_fill_width);
    }

    // Update max drawdown text and bar
    string max_text = StringFormat("Max DD: %.2f%% (Limit: %.2f%%)", max_dd_pct, max_limit_pct);
    if(ObjectFind(chart_id, OBJ_DD_MAX_LABEL) != -1)
    {
        ObjectSetString(chart_id, OBJ_DD_MAX_LABEL, OBJPROP_TEXT, max_text);
    }
    
    // Update max bar fill
    if(ObjectFind(chart_id, OBJ_DD_MAX_BAR_FILL) != -1)
    {
        int max_fill_width = (int)MathMin(DD_BAR_WIDTH, DD_BAR_WIDTH * max_dd_pct / max_limit_pct);
        ObjectSetInteger(chart_id, OBJ_DD_MAX_BAR_FILL, OBJPROP_XSIZE, max_fill_width);
    }

    ChartRedraw(chart_id);
}

//+------------------------------------------------------------------+
//| Initialize Drawdown Tracking                                    |
//+------------------------------------------------------------------+
void InitializeDrawdownTracking()
{
    // Initialize or retrieve stored all-time high
    if(!GlobalVariableCheck("DD_AllTimeHigh"))
        GlobalVariableSet("DD_AllTimeHigh", AccountInfoDouble(ACCOUNT_EQUITY));
    g_all_time_high = GlobalVariableGet("DD_AllTimeHigh");

    // Set today's high to current equity
    g_daily_high = AccountInfoDouble(ACCOUNT_EQUITY);
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    g_last_day_dd = dt.day;
}

//+------------------------------------------------------------------+
//| Update Drawdown Metrics                                         |
//+------------------------------------------------------------------+
void UpdateDrawdownMetrics(bool show_dashboard, double daily_limit_pct, double max_limit_pct)
{
    // Check for new day
    MqlDateTime dt;
    TimeToStruct(TimeCurrent(), dt);
    int today = dt.day;
    if(today != g_last_day_dd)
    {
        // New day: reset daily high
        g_last_day_dd = today;
        g_daily_high = AccountInfoDouble(ACCOUNT_EQUITY);
    }

    double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);

    // Update watermarks
    if(current_equity > g_daily_high) g_daily_high = current_equity;
    if(current_equity > g_all_time_high) 
    {
        g_all_time_high = current_equity;
        GlobalVariableSet("DD_AllTimeHigh", g_all_time_high);
    }

    // Calculate drawdowns
    double daily_dd_pct = (g_daily_high > 0) ? (g_daily_high - current_equity) / g_daily_high * 100.0 : 0.0;
    double max_dd_pct = (g_all_time_high > 0) ? (g_all_time_high - current_equity) / g_all_time_high * 100.0 : 0.0;

    // Update the dashboard if enabled
    if(show_dashboard)
    {
        Dashboard_UpdateDrawdown(daily_dd_pct, max_dd_pct, daily_limit_pct, max_limit_pct);
    }
}
