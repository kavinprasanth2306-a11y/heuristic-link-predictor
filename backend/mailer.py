"""
CupidGraph Automated SMTP Mailer Module
Sender: darkin2306@gmail.com
Sends an automated, styled HTML welcome & compatibility receipt upon profile completion.
Supports fallback/mock logging if live credentials or network blocks are encountered.
"""

import smtplib
import os
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

SENDER_EMAIL = os.environ.get("CUPID_SMTP_USER", "darkin2306@gmail.com")
# In production, set CUPID_SMTP_PASS environment variable with Google App Password
SENDER_PASSWORD = os.environ.get("CUPID_SMTP_PASS", "") 
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587

def send_welcome_compatibility_email(to_email, user_name, user_id, vector_10d, match_id="CG-7829-AI"):
    """
    Sends an automated HTML welcome receipt with the user's 10-D compatibility vector baseline,
    Match ID, and AI community safety guidelines.
    """
    subject = f"Welcome to CupidGraph, {user_name}! Your Match ID: {match_id}"
    
    # Vector formatted for display
    vector_str = ", ".join([f"{v:.2f}" for v in vector_10d])

    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <style>
        body {{ font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #0b0f19; color: #f1f5f9; padding: 20px; }}
        .container {{ max-width: 600px; margin: 0 auto; background: #141926; border-radius: 20px; border: 1px solid #334155; padding: 30px; }}
        .header {{ text-align: center; border-bottom: 1px solid #334155; padding-bottom: 20px; }}
        .logo {{ font-size: 28px; font-weight: 800; color: #ff4458; letter-spacing: 1px; }}
        .badge {{ background: rgba(255, 68, 88, 0.15); color: #ff4458; padding: 6px 14px; border-radius: 20px; font-weight: bold; font-size: 13px; display: inline-block; margin-top: 10px; }}
        .content {{ padding: 25px 0; line-height: 1.6; font-size: 14px; color: #cbd5e1; }}
        .vector-box {{ background: #0f172a; border: 1px solid #00f0ff33; border-radius: 12px; padding: 15px; margin: 20px 0; }}
        .vector-title {{ font-size: 12px; color: #00f0ff; font-weight: bold; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }}
        .vector-vals {{ font-family: monospace; color: #38bdf8; font-size: 13px; word-break: break-all; }}
        .guidelines {{ background: rgba(16, 185, 129, 0.1); border-left: 4px solid #10b981; padding: 12px 16px; border-radius: 8px; margin: 20px 0; font-size: 13px; color: #e2e8f0; }}
        .footer {{ text-align: center; font-size: 12px; color: #64748b; border-top: 1px solid #334155; padding-top: 20px; }}
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <div class="logo">CupidGraph<span style="color:#00f0ff;">AI</span></div>
          <p style="color:#94a3b8; font-size:13px; margin:4px 0 0 0;">Graph-Theoretic Compatibility & Matchmaking Engine</p>
          <div class="badge">Match ID: {match_id}</div>
        </div>
        
        <div class="content">
          <h2 style="color:#ffffff; margin-top:0;">Welcome aboard, {user_name}! 👋</h2>
          <p>Congratulations on completing the <strong>Mandatory 10-Question Compatibility Wizard</strong>. Your orthogonal preferences have been successfully projected into CupidGraph's multi-dimensional vector space.</p>
          
          <div class="vector-box">
            <div class="vector-title">📐 Your Normalized 10-D Compatibility Vector:</div>
            <div class="vector-vals">[{vector_str}]</div>
            <p style="font-size:11px; color:#64748b; margin:6px 0 0 0;">Used to calculate exact Cosine Similarity and Adamic-Adar social proximity for candidate matches.</p>
          </div>

          <div class="guidelines">
            <strong>🛡️ Community Safety & Graph Integrity:</strong><br>
            • Every profile on CupidGraph is photo-verified.<br>
            • Mutual introduction chains are computed using A* Heuristic Search to maximize trust.<br>
            • Be respectful, authentic, and keep communications polite.
          </div>

          <p>Open the CupidGraph app to start exploring your candidate deck, inspect your community Minimum Spanning Tree (MST), and view real-time compatibility scores!</p>
        </div>

        <div class="footer">
          Sent automatically via CupidGraph Mailer (<code>{SENDER_EMAIL}</code>)<br>
          Course: 25CS301 - Artificial Intelligence | University Micro-Project
        </div>
      </div>
    </body>
    </html>
    """

    # If live SMTP password is configured, attempt live dispatch
    if SENDER_PASSWORD:
        try:
            msg = MIMEMultipart("alternative")
            msg["Subject"] = subject
            msg["From"] = f"CupidGraph Matchmaking <{SENDER_EMAIL}>"
            msg["To"] = to_email
            msg.attach(MIMEText(html_content, "html"))

            server = smtplib.SMTP(SMTP_SERVER, SMTP_PORT)
            server.starttls()
            server.login(SENDER_EMAIL, SENDER_PASSWORD)
            server.sendmail(SENDER_EMAIL, [to_email], msg.as_string())
            server.quit()
            print(f"[SMTP SUCCESS] Welcome email dispatched to {to_email} via {SENDER_EMAIL}")
            return {"status": "sent", "recipient": to_email, "mode": "live_smtp"}
        except Exception as e:
            print(f"[SMTP WARNING] Live dispatch failed ({e}). Falling back to mock dispatch.")

    # Graceful standard mock fallback for evaluation
    print("=" * 60)
    print(f"[MOCK SMTP DISPATCH] From: {SENDER_EMAIL} | To: {to_email}")
    print(f"Subject: {subject}")
    print(f"10-D Vector Baseline: [{vector_str}]")
    print("=" * 60)
    return {"status": "mock_sent", "recipient": to_email, "sender": SENDER_EMAIL, "mode": "mock_fallback"}
