// SMS Service using Twilio
// Install: npm install twilio

class SmsService {
  constructor() {
    // Initialize Twilio only if credentials are provided
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
      try {
        const twilio = require('twilio');
        this.client = twilio(
          process.env.TWILIO_ACCOUNT_SID,
          process.env.TWILIO_AUTH_TOKEN
        );
        this.fromNumber = process.env.TWILIO_PHONE_NUMBER;
        console.log('✅ Twilio SMS service initialized');
      } catch (error) {
        console.log('⚠️ Twilio not installed or configured. SMS will be disabled.');
        this.client = null;
      }
    } else {
      console.log('⚠️ SMS service not configured. Set TWILIO credentials in .env');
      this.client = null;
    }
  }

  // Send OTP via SMS
  async sendOtpSms(to, otp) {
    try {
      if (!this.client) {
        // In development/testing mode without Twilio
        console.log('📱 SMS Service (Test Mode)');
        console.log(`Would send OTP to ${to}: ${otp}`);
        return {
          success: true,
          messageId: 'test_' + Date.now(),
          testMode: true,
          message: 'SMS service not configured - check console for OTP'
        };
      }

      // Send real SMS via Twilio
      const message = await this.client.messages.create({
        body: `Your FinSathi password reset OTP is: ${otp}. Valid for 5 minutes. Do not share this code.`,
        from: this.fromNumber,
        to: to
      });

      console.log('✅ OTP SMS sent successfully');
      console.log('Message SID:', message.sid);

      return {
        success: true,
        messageId: message.sid,
        testMode: false
      };
    } catch (error) {
      console.error('❌ Error sending OTP SMS:', error);
      throw new Error('Failed to send OTP SMS');
    }
  }

  // Send password changed notification via SMS
  async sendPasswordChangedSms(to) {
    try {
      if (!this.client) {
        console.log('📱 SMS Service (Test Mode)');
        console.log(`Would send password change notification to ${to}`);
        return { success: true, testMode: true };
      }

      const message = await this.client.messages.create({
        body: `Your FinSathi account password was changed successfully. If you didn't make this change, contact support immediately.`,
        from: this.fromNumber,
        to: to
      });

      console.log('✅ Password changed SMS sent');
      return {
        success: true,
        messageId: message.sid
      };
    } catch (error) {
      console.error('❌ Error sending SMS:', error);
      return { success: false };
    }
  }

  // Check if SMS service is available
  isAvailable() {
    return this.client !== null;
  }
}

module.exports = new SmsService();
