---
sidebar_navigation:
  title: Enterprise cloud FAQ
  priority: 001
description: Frequently asked questions regarding Enterprise cloud
robots: index, follow
keywords: Enterprise cloud FAQ, Cloud Edition, hosted by OpenProject
---

# Frequently asked questions (FAQ) for Enterprise cloud

## How can I book additional users for the Enterprise cloud?

You can do this in your OpenProject instance in the administration. The number of users can be increased in steps of 5. Find out [here](../manage-cloud-subscription/#upgrade-or-downgrade-subscription) how to change the number of users in your system administration. A reduction in the number of users takes effect at the beginning of the next subscription period.

## How can I change my payment details (e.g. new credit card)?

Please have a look at [this instruction](../manage-cloud-subscription/).


## Does OpenProject comply with GDPR?

The protection of personal data is for OpenProject more than just a legal requirement. We are highly committed to data security and privacy. We are a company based in Berlin, the European Union, and the awareness and importance for data security and privacy actions have always been a major topic for us. OpenProject complies with GDPR and we handle our customer’s data with care. Get more detailed information [here](https://www.openproject.org/gdpr-compliance/).

## Is the Enterprise cloud certified?

The data center (AWS) we use for Enterprise Cloud Edition is ISO27001 certified.

For more information please visit the [information regarding security measures](https://www.openproject.org/legal/data-processing-agreement/technical-and-organizational-data-security-measures) on our website.

## Where geographically is the OpenProject Enterprise cloud data stored?

The OpenProject Enterprise cloud environment is hosted on a logically isolated virtual cloud at Amazon Web Services with all services being located in Ireland. AWS is a GDPR compliant cloud infrastructure provider with extensive security and compliance programs as well as unparalleled access control mechanisms to ensure data privacy. Employed facilities are compliant with the ISO 27001 and 27018 standards. OpenProject Enterprise cloud environment is continuously backing up user data with data at rest being fully encrypted with AES-256. Each individual's instance is logically separated and data is persisted in a unique database schema, reducing the risk of intersection or data leaks between instances. You can find more information [here](https://www.openproject.org/gdpr-compliance/).


## Can I get a custom domain name instead of example.openproject.com?

Yes, you can create your custom domain name. For this service we charge €100 once-off. Please add it in your booking process (will soon be available) or contact us via email (support@openproject.com).

## Can I import my OpenProject community instance into my Enterprise cloud environment?

Yes, we provide an upload possibility of your data to move from a Community Edition installation to the Enterprise cloud edition.
To import your community instance into our cloud environment, please send us the following files:

1. The database SQL dump of your local installation
2. The attachments of your local installation

For a package-based installation, you can create both as root user on your environment as follows: `openproject run backup`
This creates the attachment and PostgreSQL-dump or MySQL-dump under /var/db/openproject/backup.
If you are still running OpenProject under MySQL, your dump will be converted to PostgreSQL before importing, we will do this for you. More information about the backup tool can be found [here](../../../installation-and-operations/operation/backing-up/).
Please upload these documents as an attachment to a work package within your new OpenProject Enterprise cloud environment and send us the link to this work package via email.

## How can I export the documents loaded on OpenProject?

Currently, there is unfortunately no option to export all the documents in OpenProject at once. We could manually export the entire database (including the attachments) for you. Due to the manual effort, we would however need to charge a service fee for this. Please contact sales@openproject.com.

## Is it possible to access the PostgreSQL tables (read-only) on a hosted OpenProject instance via ODBC or another protocol (e.g. to extract data for PowerBI)?

Access to the database (including the PostgreSQL tables) is restricted for the Enterprise cloud edition due to technical and security reasons. Instead, you can use the OpenProject [API](../../../api) to both read and write data (where supported). If you require direct database access, you may want to take a look at the OpenProject [Enterprise on-premises edition](https://www.openproject.org/enterprise-edition) which you can run on your own server.

