# Access the app online

You can now access this app [here](https://p76zlz-katarzyna0zofia0kedzierska0kasia0.shinyapps.io/interactive_app/). Signing up and deploying the app (including installing a package) took me 3 minutes. You can try it too!

# How I deployed this app?

I went to [shinyapps.io/](https://www.shinyapps.io/) and Signed Up. 

Then I followed the instructions I saw when logged in:

1. I installed `rsconnect` with `install.packages('rsconnect')`.  
2. Then, I copied the `rsconnect::setAccountInfo(xxx)` details.
3. And then, I deployed it:

```{r}
library(rsconnect)
rsconnect::deployApp('interactive_app/')
```

Which generated the following output:

```
Preparing to deploy application...DONE
Uploading bundle for application: XXX...DONE
Deploying bundle: XXXX for application: XXX ...
Waiting for task: XXXX
  building: Processing bundle: XXXX
  building: Parsing manifest
  building: Building image: XXXX
  building: Fetching packages
  building: Installing packages
  building: Installing files
  building: Pushing image: XXX
  deploying: Starting instances
  rollforward: Activating new instances
  unstaging: Stopping old instances
Application successfully deployed to https://p76zlz-katarzyna0zofia0kedzierska0kasia0.shinyapps.io/interactive_app/
```

And voila! The app is up and running [https://p76zlz-katarzyna0zofia0kedzierska0kasia0.shinyapps.io/interactive_app/](https://p76zlz-katarzyna0zofia0kedzierska0kasia0.shinyapps.io/interactive_app/).
