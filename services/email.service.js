const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    // Create transporter based on environment
    if (process.env.EMAIL_SERVICE === 'gmail') {
      // Gmail configuration
      this.transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASSWORD // App password, not regular password
        }
      });
    } else if (process.env.SMTP_HOST) {
      // Custom SMTP configuration
      this.transporter = nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: process.env.SMTP_PORT || 587,
        secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASSWORD
        }
      });
    } else {
      // Development mode - use ethereal.email (fake SMTP service)
      console.log('⚠️ No email service configured. Using test mode.');
      this.useFakeService = true;
    }
  }

  // Initialize fake email service for testing
  async initFakeService() {
    if (this.useFakeService && !this.transporter) {
      try {
        const testAccount = await nodemailer.createTestAccount();
        this.transporter = nodemailer.createTransport({
          host: 'smtp.ethereal.email',
          port: 587,
          secure: false,
          auth: {
            user: testAccount.user,
            pass: testAccount.pass
          }
        });
        console.log('✅ Fake email service initialized for testing');
      } catch (error) {
        console.error('❌ Error creating fake email service:', error);
      }
    }
  }

  // Send OTP email
  async sendOtpEmail(to, otp, userName = 'User') {
    try {
      // Initialize fake service if needed
      if (this.useFakeService) {
        await this.initFakeService();
      }

      const mailOptions = {
        from: `"${process.env.APP_NAME || 'FinSathi'}" <${process.env.EMAIL_USER || 'noreply@finnsathi.com'}>`,
        to: to,
        subject: 'Password Reset OTP - FinSathi',
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .otp-box { background: white; border: 2px dashed #667eea; padding: 20px; text-align: center; margin: 20px 0; border-radius: 8px; }
              .otp-code { font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 8px; }
              .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
              .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 20px 0; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🔐 Password Reset Request</h1>
              </div>
              <div class="content">
                <p>Hello <strong>${userName}</strong>,</p>
                <p>We received a request to reset your password. Use the OTP below to complete the process:</p>
                
                <div class="otp-box">
                  <p style="margin: 0; font-size: 14px; color: #666;">Your OTP Code</p>
                  <div class="otp-code">${otp}</div>
                  <p style="margin: 10px 0 0 0; font-size: 12px; color: #999;">Valid for 5 minutes</p>
                </div>

                <div class="warning">
                  <strong>⚠️ Security Note:</strong> This OTP will expire in 5 minutes. If you didn't request this, please ignore this email or contact support immediately.
                </div>

                <p>For security reasons:</p>
                <ul>
                  <li>Never share this OTP with anyone</li>
                  <li>FinSathi staff will never ask for your OTP</li>
                  <li>This OTP can only be used once</li>
                </ul>

                <p>Best regards,<br><strong>FinSathi Team</strong></p>
              </div>
              <div class="footer">
                <p>This is an automated message, please do not reply to this email.</p>
                <p>&copy; ${new Date().getFullYear()} FinSathi. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        `
      };

      const info = await this.transporter.sendMail(mailOptions);
      
      console.log('✅ OTP email sent successfully');
      console.log('Message ID:', info.messageId);
      
      // If using fake service, log the preview URL
      if (this.useFakeService) {
        console.log('📧 Preview URL:', nodemailer.getTestMessageUrl(info));
        console.log('⚠️ Using test email service - Check console for preview URL');
      }

      return {
        success: true,
        messageId: info.messageId,
        previewUrl: this.useFakeService ? nodemailer.getTestMessageUrl(info) : null
      };
    } catch (error) {
      console.error('❌ Error sending OTP email:', error);
      throw new Error('Failed to send OTP email');
    }
  }

  // Send password changed confirmation email
  async sendPasswordChangedEmail(to, userName = 'User') {
    try {
      if (this.useFakeService) {
        await this.initFakeService();
      }

      const mailOptions = {
        from: `"${process.env.APP_NAME || 'FinSathi'}" <${process.env.EMAIL_USER || 'noreply@finnsathi.com'}>`,
        to: to,
        subject: 'Password Changed Successfully - FinSathi',
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <style>
              body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
              .success-box { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 8px; margin: 20px 0; }
              .footer { text-align: center; margin-top: 20px; font-size: 12px; color: #666; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>✅ Password Changed</h1>
              </div>
              <div class="content">
                <p>Hello <strong>${userName}</strong>,</p>
                
                <div class="success-box">
                  <p style="margin: 0;"><strong>Your password has been changed successfully!</strong></p>
                </div>

                <p>This email confirms that your FinSathi account password was changed on ${new Date().toLocaleString()}.</p>

                <p><strong>If you made this change:</strong><br>
                No further action is needed. You can now log in with your new password.</p>

                <p><strong>If you didn't make this change:</strong><br>
                Please contact our support team immediately at <a href="mailto:support@finnsathi.com">support@finnsathi.com</a></p>

                <p>Best regards,<br><strong>FinSathi Security Team</strong></p>
              </div>
              <div class="footer">
                <p>&copy; ${new Date().getFullYear()} FinSathi. All rights reserved.</p>
              </div>
            </div>
          </body>
          </html>
        `
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('✅ Password changed confirmation email sent');
      
      return {
        success: true,
        messageId: info.messageId
      };
    } catch (error) {
      console.error('❌ Error sending password changed email:', error);
      // Don't throw error for confirmation emails
      return { success: false };
    }
  }

  // Verify email service connection
  async verifyConnection() {
    try {
      if (this.useFakeService) {
        await this.initFakeService();
      }
      
      await this.transporter.verify();
      console.log('✅ Email service is ready');
      return true;
    } catch (error) {
      console.error('❌ Email service verification failed:', error);
      return false;
    }
  }
}

module.exports = new EmailService();
