# tidily automating email


library(blastula)
library(tidyverse)

# as a one time task, set up a credentials file
# running the function below will result in a prompt to enter your password
# be aware this is stored in plain text within the file
# additionally, if you are actually using gmail as in this eample
# you will need to configure your account appropriately and obey free smtp limits
# or upgrade.  See, e.g., https://www.gmass.co/blog/gmail-smtp/

# create_smtp_creds_file(file='secrets',
#                        user='<your user name>,
#                        host='smtp.gmail.com',
#                        port=465,
#                        use_ssl=TRUE)

#using blastula, we can render an .RMD to email
render_email('Message.RMD',render_options=
                      list(
                        params=list(state='Illinois',name='George',signoff='Data Science Team')
                        )
                    )

#But, we are automating this so we don't have to send many emails manually
#So let's create a mailing list and use the tidyverse to mail merge

mailList<-tibble(name=c('Tom','Dick','Harry'),
       address=c('tom@company.com','dick@company.com','harry@company.com'),
       state=c('Illinois','California','Hawaii'),
       signoff=rep('Friendly Data Science Folks',3))
#if we write ourselves a function to render the emails that takes the params as arguments:
makeMessages<-function(stateName,personName,signature,rmdFile){
    email<-render_email(rmdFile,render_options=
                   list(
                     params=list(state=stateName,name=personName,signoff=signature)
                   )
    )
    return(email)
}

#we can use pamp to create a list of emails in a new column
#note that function name is bare of the parentheses
mailList<-mailList%>%mutate(email=pmap(list(state,name,signoff),makeMessages,rmdFile='Message.RMD'))

#you can view an email to make sure it rendered correctly
mailList$email[[3]]

#sending emails via SMTP with blastula is straight forward using the smtp_send function

#the return value of smtp_send is NULL after a successful email
#and the sent email is a 'side effect' of the smpt_send function
#but keeping the results in a tibble makes it easy to see if there was a problem
mailList%>%mutate(returnCode=pmap(list(email=email,to=address),smtp_send,from='<your email here>',
                                  subject='Urgent: Covid Update',credentials=creds_file('secrets')))
