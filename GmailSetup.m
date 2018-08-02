% This function is for sending email. The password is now shown. You should
% change the email and specify the password , otherwise this option won't
% work

function GmailSetup
myaddress = 'tariffapp@gmail.com';
mypassword = ''; % Change the email and password

setpref('Internet','E_mail',myaddress);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',myaddress);
setpref('Internet','SMTP_Password',mypassword);

props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', ...
    'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

end