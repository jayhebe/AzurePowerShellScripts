Configuration DeployWebPage
{
    node "localhost"
    {
        WindowsFeature IIS
        {
            Ensure = "Present"
            Name = "Web-Server"
        }

        File WebPage
        {
            Ensure = "Present"
            DestinationPath = "C:\inetpub\wwwroot\index.html"
            Force = $true
            Type = "File"
            Contents = "<html><body><h1>Hello Web Page!</h1></body></html>"
        }
    }
}