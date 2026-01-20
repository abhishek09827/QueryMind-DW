
import streamlit as st

def kpi_card(title: str, value: any, delta: any = None, prefix: str = "", suffix: str = ""):
    """
    Renders a KPI card using st.metric.
    Handles formatting of values.
    """
    formatted_value = value
    
    if isinstance(value, (int, float)):
        if "Revenue" in title or "Value" in title or prefix == "$":
             formatted_value = f"${value:,.2f}"
        elif isinstance(value, float):
             formatted_value = f"{value:,.2f}"
        else:
             formatted_value = f"{value:,}"
    
    formatted_value = f"{prefix}{formatted_value}{suffix}"
    
    display_delta = ""
    if delta is not None:
        delta_color = "text-emerald-500" if delta > 0 else "text-rose-500" if delta < 0 else "text-slate-500"
        delta_arrow = "↑" if delta > 0 else "↓" if delta < 0 else "—"
        display_delta = f'<span class="{delta_color} text-sm font-semibold ml-2">{delta_arrow} {abs(delta)}%</span>'
    
    st.markdown(f"""
        <div class="tailwind-card">
            <div class="text-slate-500 text-xs font-semibold uppercase tracking-wide">{title}</div>
            <div class="mt-2 flex items-baseline">
                <span class="text-3xl font-bold text-slate-900">{formatted_value}</span>
                {display_delta}
            </div>
        </div>
    """, unsafe_allow_html=True)
