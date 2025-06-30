import smtplib
from email.message import EmailMessage

def send_email(subject, body, to_email):
    smtp_server = 'smtp.gmail.com'  # Change if using different SMTP server
    smtp_port = 587
    sender_email = 'infrastructure@redbackops.com'  # Your email address
    sender_password = 'Vumo3117'  # App password if using Gmail with 2FA

    msg = EmailMessage()
    msg['Subject'] = subject
    msg['From'] = sender_email
    msg['To'] = to_email
    msg.set_content(body)

    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.send_message(msg)
        print(f"Email sent to {to_email}: {subject}")
    except Exception as e:
        print(f"Failed to send email: {e}")
