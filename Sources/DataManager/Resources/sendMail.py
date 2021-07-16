# coding: UTF-8

import sys
import pathlib
import base64
import smtplib
import ssl
import os
from email.mime.text import MIMEText
from email.utils import formatdate
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart

import json

try:
    if len(sys.argv) < 5:
        raise AttributeError("コマンドライン引数は最低5つ必要です（送信元メール、受信先メール、CC、タイトル、本文、(オプション)添付ファイル）")


    mail_from = sys.argv[1]

    mail_to = sys.argv[2]

    mail_cc = sys.argv[3]

    attach = sys.argv[4]

    title = sys.argv[5]

    body = " ".join(sys.argv[6:]) #本文中に半角スペースが入ってる可能性を勘案

    msg = MIMEMultipart()

    charset = "utf-8"
    if charset == "utf-8":
        bd = MIMEText(body, "plain", charset)
    elif charset == "iso-2022-jp":
        bd = MIMEText(base64.b64encode(body.encode(charset, "ignore")), "plain", charset)
    msg.attach(bd)

    config_file = os.path.join(pathlib.Path(__file__).parent.absolute() , "mailConfig.json")
    # 保存したファイルを読み込む
    with open(config_file, "r") as f:
        conf = json.load(f)
    


    """
    (2) MIMEメッセージに必要なヘッダを付ける
    """
    msg.add_header("Content-Transfer-Encoding", "base64")
    msg["Subject"] = title
    msg["From"] = mail_from
    msg["To"] = mail_to
    msg["Cc"] = mail_cc
    msg["Bcc"] = ""
    msg["Date"] = formatdate(None,True)

    # 添付ファイル
    if len(attach) != 0:
        with open(attach, "rb") as a:
            mb = MIMEApplication(a.read(), Name="出荷実績.txt")
        mb.add_header("Content-Disposition", "attachment", filename="出荷実績.txt")
        msg.attach(mb)

    """
    (3) SMTPクライアントインスタンスを作成
    """
    host = conf["host"]
    port = conf["port"]
    method = conf["method"]

    port = conf["port"]
    if method == "noencrypt":
        smtpclient = smtplib.SMTP(host, port, timeout=10)
    elif method == "starttls":
        smtpclient = smtplib.SMTP(host, port, timeout=10)
        smtpclient.ehlo()
        smtpclient.starttls()
        smtpclient.ehlo()
    elif method == "ssl":
        context = ssl._create_unverified_context()
        smtpclient = smtplib.SMTP_SSL(host, port, timeout=10, context=context)
    smtpclient.set_debuglevel(2) # サーバとの通信のやり取りを出力してくれる


    """
    (4) サーバーにログインする
    """
    username = conf["username"]
    password = conf["password"]
    smtpclient.login(username, password)


    """
    (5) メールを送信する
    """
    smtpclient.send_message(msg)
    smtpclient.quit()
except Exception as e:
    # エラーを返す(先頭の!がエラーの印)
    print('!SendMailError:',str(sys.exc_info()[0]), str(sys.exc_info()[1]), end='')