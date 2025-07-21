# Internet is Nasty

A horror-themed web application that visualizes real-time connection attempts to common network ports on a server.

## Overview

This project consists of two main parts:

1.  **A Python Backend**: Built with Flask, it serves the frontend application and listens on a list of common network ports (e.g., 21, 22, 80, 445).
2.  **A Web Frontend**: A single-page interface styled like a horror movie computer terminal. It uses WebSockets to receive real-time data from the backend every time a connection attempt is detected on one of the monitored ports.

## Tech Stack

*   **Backend**: Python, Flask, Flask-SocketIO
*   **Frontend**: HTML, CSS, JavaScript, Socket.IO Client

## Local Development Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd Internetisnasty
    ```

2.  **Create and activate a virtual environment:**
    ```bash
    # For Windows
    python -m venv venv
    .\venv\Scripts\activate

    # For macOS/Linux
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install the dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Run the application:**
    ```bash
    python app.py
    ```
    The application will be available at `http://127.0.0.1:5000`.

## AWS Deployment Guide (Using Elastic Beanstalk)

Deploying this application to a public server is what makes it interesting. AWS Elastic Beanstalk is a straightforward way to get it running.

### Prerequisites

*   An AWS Account.
*   [AWS CLI](https://aws.amazon.com/cli/) installed and configured on your machine.

### Deployment Steps

1.  **Prepare the Application Bundle**:
    Create a `.zip` file containing all the project files (`app.py`, `requirements.txt`, `templates/`, `static/`). Do **not** include the `venv` directory.

2.  **Create an Elastic Beanstalk Application**:
    Navigate to the Elastic Beanstalk service in the AWS Management Console.
    *   Click **"Create Application"**.
    *   Enter an application name (e.g., `internet-is-nasty`).
    *   Under **"Platform"**, select **Python**.
    *   For **"Application code"**, choose **"Upload your code"** and select the `.zip` file you created.

3.  **Configure Environment and Launch**:
    *   Let Elastic Beanstalk create a new environment for you.
    *   Review the settings and click **"Create application"**. AWS will provision the necessary resources (like an EC2 instance) and deploy your code.

4.  **Configure the Security Group**:
    **This is a critical step for the application to work.** The server needs to accept traffic on the ports it's monitoring.
    *   Navigate to the **EC2 service** in the AWS Console.
    *   Find the instance that was created by Elastic Beanstalk.
    *   Go to the **"Security"** tab and click on the security group associated with the instance.
    *   Click **"Edit inbound rules"**.
    *   For each port you are monitoring (e.g., 21, 22, 23, 80, 445, etc.), add a new rule:
        *   **Type**: Custom TCP
        *   **Port Range**: The port number (e.g., `21`)
        *   **Source**: Anywhere-IPv4 (`0.0.0.0/0`)
    *   Save the rules.

Once deployed, Elastic Beanstalk will provide you with a public URL where you can see your application live and watch the connection attempts roll in.
