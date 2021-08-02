---
sidebar_navigation:
  title: Email
  priority: 760
description: Email configuration in OpenProject.
robots: index, follow
keywords: email configuration
---
# Email settings

Configure **email settings** in OpenProject, i.e. email notifications and incoming email configuration.

Navigate to *Administration* -> *Email*.


| Topic                                                | Content                                        |
| ---------------------------------------------------- | ---------------------------------------------- |
| [Email notifications](#email-notifications-settings) | How to configure outgoing email notifications? |
| [Incoming emails](#incoming-emails-settings)         | How to configure settings for inbound emails?  |


## Email notifications settings

To adapt email notification settings, go to Email and choose *Email notifications*.

1. **Emission email address**. This email address will be shown as the sender for the email notifications sent by OpenProject (for example,  when a work package is changed).
2. Activate **blind carbon copy recipients** (bcc).
3. Define if the email should be formatted in **plain text** (no HTML).
4. Select the default notification options. The default notification can be adapted in the [user profile](../../getting-started/my-account/#email-notifications).
5. Select for which **actions email notification should be sent**. You have the possibility to check all or uncheck all at the top right.

![System-admin-guide-emails](System-admin-guide-emails.png)

The frequency of sending e-mails per work package can be set in [this way](../system-settings/display-settings/#time-and-date-formatting,-aggregation-of-changes-in-activity).


### Configure email header and email footer

Configure your notification email header and footer which will be sent out for email notifications from the system.

1. **Formulate header and/or footer** for the email notifications. These are used for all the email notifications from OpenProject (e.g. when creating a work package).
2. **Choose a language** for which the email header and footer will apply.
3. **Send a test email**.
   Please note: This test email does *not* test the notifications for work package changes etc. Find out more in [this FAQ](../../installation-and-operations/installation-faq#i-dont-receive-emails-test-email-works-fine-but-not-the-one-for-work-package-updates).
4. Do not forget to **save** your changes.![Sys-admin-email-notifications-email-header-footer](Sys-admin-email-notifications-email-header-footer.png)



## Incoming emails settings

To adapt incoming email settings, go to *Email* -> *Incoming Email*. Here you can configure the following options.

1. **Define after which lines an email should be truncated**. This setting allows shortening email after the entered lines.
2. Specify a **regular expression** to truncate emails.
3. **Ignore mail attachment** of the specified names in this list.
4. Do not forget to **save** the changes.

![System-admin-guide-incoming-email](System-admin-guide-incoming-email.png)

**To set up incoming email**, please visit our [Operations guide](../../installation-and-operations/configuration/incoming-emails/).

For frequently asked questions regarding the incoming emails feature please have a look at the respective [FAQ section](./email-faq).