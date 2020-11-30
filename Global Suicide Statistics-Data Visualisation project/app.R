
library(shiny)     #for building the dashboard
library(shinythemes)# for background themes
library(leaflet)   # for drawing world map
library(ggplot2)   # for plots
library(dplyr)     # for dataframe manipulation
library(DT)        # for datatable
library(rgdal)     # R Geospatial Data Abstraction Library
library(plotly)    # for interactive plots
#library(gganimate) # for animation
#library(gifski)     #for combining images as gif

#load the dataset

suicide=read.csv('sucide.csv',header=T)

#load the shape files to plot the world map with continents
#data downloaded from below link
#https://hub.arcgis.com/datasets/esri::world-continents/data?geometry=-174.023%2C-84.708%2C174.023%2C57.126&selectedAttribute=CONTINENT
myspdf=readOGR(dsn="./World_Continents",layer="4a7d27e1-84a3-4d6a-b4c2-6b6919f3cf4b202034-1-2zg7ul.ht5ut")

#create a new tibble with suicide statistics for continents
continent_tibble <- suicide %>%
   select(Continent, Suicides_no, Population) %>%
   group_by(Continent) %>%
   summarize(suicide_capita = round((sum(Suicides_no)/sum(Population))*100000, 2)) %>%
   arrange(suicide_capita)

#add extra continents which are in shape files dataset but not in our suicide dataset
continent_tibble<-rbind(continent_tibble,c("Oceania",0))
continent_tibble<-rbind(continent_tibble,c("Antarctica",0))

#create a list with the desired order of continents
#myspdf@data contains the data of the spatial data frame.

conti <- c("Africa", "Asia", "Australia","North America","Oceania","South America","Antarctica","Europe")

#order the continents according to the myspdf@data using match function
#https://stackoverflow.com/questions/26548495/reorder-rows-using-custom-order

continent_tibble<- continent_tibble %>%
   slice(match(conti,Continent))

#convert the tibble to a dataframe
continent<- as.data.frame(continent_tibble)

#add the column suicide_capita to the myspdf dataframe so that we can use that information
#to display on the map
myspdf@data$suicide_capita=continent[,2]

#write the new changes to the shape files
#writeOGR(myspdf, ".","new-one", driver="ESRI Shapefile",overwrite_layer=TRUE) 

#https://rstudio.github.io/leaflet/choropleths.html
#define the bins for the colors
bins <- c(0,2,4,6,8,10,12,14,16,18,Inf)

#use colorBin function to design the color palate 
pal <- colorBin("YlOrRd", domain = myspdf@data$suicide_capita, bins = bins)

#design custom labels to show on the map
labels <- sprintf(
   "<strong>%s</strong><br/>%s Suicides (per 100k people)",
   myspdf@data$CONTINENT, myspdf@data$suicide_capita
) %>% lapply(htmltools::HTML)

#animated line chart on home page
#This code is written to produce the animated line chart on the home page
#commenting this code to save computation time.The libraries corresponding to this code are also commented above.
#The gif produced is saved in www folder.
   
   # p=suicide %>%
   #    group_by(Year) %>%
   #    summarize(population = sum(Population),
   #              suicides = sum(Suicides_no),
   #              suicides_per_100k = (suicides / population) * 100000) %>%
   #    ggplot(aes(Year,suicides_per_100k)) +
   #    geom_line(col="steelblue",size=1.5)+geom_point()+ggtitle("Suicide trend in World")+
   #    xlab("Year")+ylab("Suicides per 100k population")+
   #    theme_bw(base_size = 18)+
   #    transition_reveal(Year)
   # 
   # anim_save("outfile.gif", animate(p))

# Define UI for the application
ui <- fluidPage(theme = shinytheme("united"),
                navbarPage("Global suicides",
                           # declare the first tab 
                           tabPanel("Introduction",
                                    div(class="outer",
                                        
                                        #Absolute panel at the side:
                                        absolutePanel(id = "controls", class = "panel panel-default", fixed = FALSE,
                                                      draggable = FALSE, top = 80, left = "auto", right = "auto", bottom = "auto",
                                                      width = "97%", height = "auto",
                                                      
                                                      #Heading
                                                      titlePanel(h1("Global Suicides!!",
                                                                    style='background-color:coral;
                                                            padding-left: 15px')), 
                                                      
                                                      #display image on main page
                                                      div(img(src='depression.jpg',align="center",style="width:70%;height:400px"), style="text-align: center;
                                                          background-color:#e6e6e6"),
                                                      
                                                      #display the animated line chart
                                                      div(img(src='outfile.gif',align="left",style="width: 480px"), style="text-align: center;",),
                  
                                                      #Text for description
                                                      # Appropriate font size and background color have been chosen based on human perceptual system
                                                      p("This application is intended to visualize Global Suicide Rates.It helps us to understand
                                                        how suicides vary in each country, continent and give a better picture of the age-groups
                                                        , genders and generation types committing more suicides.",style='font-size:20px'),
                                                      tags$a(href="https://www.kaggle.com/russellyates88/suicide-rates-overview-1985-to-2016", "Click here for the data source",style='font-size:20px'),
                                                      p("Suicide rates are decreasing globally. Still, one person every 40 seconds commits suicide. This application is designed so that the following things can be
                                                        found out:",style='font-size:20px'),
                                                      tags$ul(
                                                      tags$li(tags$b("Find which gender, generation type, age-groups are committing suicides in
                                                         each continent.")),
                                                      tags$li(tags$b("Find the suicide trend in each country from 1985-2015 and compare between 
                                                         different countries.")),style='background-color:#ff9999;
                                                            padding-left: 20px;font-size: 20px'),
                                                      p(tags$b("Continent statistics")," tab contains all the continents in the world where 
                                                        suicide data is available.You can click on a continent and get information based on 
                                                        4 different categories like Age-groups, Trend, Generation Type and Gender",style='font-size:20px'),
                                                      p(tags$b("Countries"),"tab allows you to analyze the suicide trend in 
                                                        each country. You can select multiple countries 
                                                        and select the range of years to show the suicide trend in that 
                                                        year.",style='font-size:20px'),
                                                      
                                        )
                                        
                                    )
                                    
                                    ),
                           #declare the second tab
                           tabPanel("Continent Statistics",
   # Application title
   titlePanel("Suicides by Continent (1985-2015)"),
   
   # first, display the world map according to the 5-design sheet 
   leafletOutput(outputId = "distPlot"),
   column(3,
          wellPanel(
             h4(
             #declare the radio-buttons 
             radioButtons("category", "Select option:",
                          c("Age-groups"="Age-groups",
                            "Trend"="Trend",
                            "Generation Type"="Generation Type",
                            "Gender"="Gender")),style='font-size:20px'
             )
          )       
   ),
   
   column(5,
          #display the plotly graph based on user's choice of the options
          plotlyOutput("changePlot")
   ),
   column(4,
          #text for description
          #font-size is selected such that it is appropriate for all users
          p("The map is an interactive world map where you can click on any continent. After clicking on a continent,
            you can see by default a graph showing Suicides of various age-groups in that continent.You
            can select any option available and you get the particular graph for that option.
            Explore gender,trend and generation type graphs and get to know how they vary in each continent.",style='font-size:20px'),
          tags$h3(tags$b("Key Takeaways")),
          p("1.South America and North America have increasing suicide trends.",style='font-size:20px'),
          p("2.Suicide rate of men is higher than women.",style='font-size:20px'),
          p("3.Overall,GI Generation committed highest number of suicides.",style='font-size:20px')
          )
),
#declare the third tab
tabPanel("Countries",
sidebarLayout(
  sidebarPanel(
     #declare the year slider
    sliderInput("slider2", label = h3("Select year"), min = 1985, 
                max = 2015, value = c(1985, 2000)),
    #declare the input search box for countries
    selectizeInput("variable", label=h3("Select countries"), choices = c(suicide$Country),selected="Albania",multiple=TRUE, options=list(create=FALSE,placeholder = 'Enter countries')),
    
    h3("Data Table"),
    #display the Data Table
    DT::dataTableOutput("table"),
    style='background-color:#e6e6e6'
  ),
 mainPanel(
   #display the line graph
   plotOutput("trendplot"),
   
   #text for description
   p("You can select the years for which you want to see the suicide trend from the slider.",style='font-size:20px;padding-left: 36px'),
   p("You can select multiple countries from the",tags$b("Select countries"),"box and observe the trends.",style='font-size:20px;padding-left: 36px'),
   p("You can also have a look at the data table displayed to get to know about the suicides each 
      year for your selected country.If you select multiple countries,they are displayed alphabetically.",
     style='font-size:20px;padding-left: 36px'),
   h3(tags$b("Key Takeaways:"),style='padding-left: 36px'),
   p("1.Russian Federation and Lithuania have the highest suicide rate.",
     style='font-size:20px;padding-left: 36px'),
   p("2.Nearly half of all countries suicide rates are changing linearly with time.",
     style='font-size:20px;padding-left: 36px'),
   p("3.Republic of Korea shows the steepest increase of suicides.",
     style='font-size:20px;padding-left: 36px'),
   p("4.Estonia shows the steepest decrease of suicides.",
     style='font-size:20px;padding-left: 36px')
 
 )
)
         
         )
))



# Define server logic required to plot the graphs 
server <- function(input, output,session) {
  ########################################### Code Starts for Continent Statistics#########################################################################################
   output$distPlot <- renderLeaflet({
      # draw the leaflet graph
      
       leaflet(data=myspdf) %>%
         addTiles() %>%
         setView(lat=10,lng=0,zoom=2)%>%
         addPolygons(                                               
            fillColor = ~pal(as.numeric(suicide_capita)),    #color the graph based on suicide_capital
            layerId=~CONTINENT,                              #declare id as continent to get continent values when clicked.
            weight=2,
            opacity=1,
            color = "white",                                 
            dashArray = "3",
            fillOpacity = 0.7,
            highlight = highlightOptions(weight=5,           #declare the high-light options
                                         color="#666",
                                         fillOpacity = 0.7,
                                         bringToFront = TRUE,
            ),
            label=labels,
            labelOptions = labelOptions(                     
               style = list("font-weight" = "normal", padding = "3px 8px"),
               textsize = "15px",
               direction = "auto")) %>%                     #add legend to the plot
         addLegend(pal = pal, values = ~suicide_capita, opacity = 0.7, title = "Suicides per 100k people",
                   position = "bottomleft") 
      
      
   })
   #capture the mouse clicks on the map. If a particular continent
   #is clicked, get the id of that continent
   observeEvent(input$distPlot_shape_click, { 
      #store the name of the id returned on click event
      name <- input$distPlot_shape_click$id
      #print(name)
      #after clicking, plot the plotly graphs
      output$changePlot <- renderPlotly ({
         
         #filter the main suicide dataframe based on the continent selected to get
         #data for that particular continent only
         newdf <- suicide[suicide$Continent == name,]
         
         #check the condition for radio button selected as Trend
         if (input$category=="Trend"){
         newdf %>%
            #group by year
            group_by(Year) %>%
               #find suicides per 100k population
            summarize(population = sum(Population), 
                      suicides = sum(Suicides_no), 
                      suicides_per_100k = round((suicides / population) * 100000,2)) %>%
               plot_ly(x=~Year,y=~suicides_per_100k,type='scatter',mode='lines+markers',     #plot the line chart
                       hovertemplate = paste('<b>Year</b>: %{x}',
                                             '<br><b>Suicides per 100K</b>: %{y}<br>'
                                             
                       )) %>%
               layout(title = paste("Suicide Trend in ",name),
                      xaxis = list(title = "Years"),
                      yaxis = list(title = "Suicides per 100k population"))
            
         }
         #check the condition for radio button selected as Age-group
         else if(input$category=="Age-groups")
         {
            modified_df<-newdf %>%
               group_by(Age) %>%
               #find suicides per 100k population
               summarize(population = sum(Population), 
                         suicides = sum(Suicides_no), 
                         suicides_per_100k = round((suicides / population) * 100000,2)) 
            modified_df$Age<-factor(modified_df$Age,levels=c("5-14 years","15-24 years","25-34 years","35-54 years",
                                                             "55-74 years","75+ years"))
               plot_ly(data=modified_df,x=~Age,y=~suicides_per_100k,type='bar',color=~Age,         #plot the bar graph
                       hovertemplate = paste('<i>Age</i>: %{x}',
                                             '<br><b>Suicides per 100K</b>: %{y}<br>'
                                             )) %>%
               layout(title = paste("Suicide Age-groups in ",name),
                      xaxis = list(title = "Age-groups"),
                      yaxis = list(title = "Suicides per 100k population"))
               
         }
         #check the condition for radio button selected as Generation Type
         else if(input$category=="Generation Type")
         {
            newdf %>%
               group_by(Generation) %>%
               #find suicides per 100k population
               summarize(population = sum(Population), 
                         suicides = sum(Suicides_no), 
                         suicides_per_100k = round((suicides / population) * 100000,2)) %>%
               plot_ly(x=~Generation,y=~suicides_per_100k,type='bar',color=~Generation,         #plot the bar graph
                       hovertemplate = paste('<i>Generation</i>: %{x}',
                                             '<br><b>Suicides per 100K</b>: %{y}<br>'
                       )) %>%
               layout(title = paste("Suicide Generation Types in",name),
                      xaxis = list(title = "Generation Type"),
                      yaxis = list(title = "Suicides per 100k population"))
               
         }
         #check the condition for radio button selected as Gender
         else if(input$category=="Gender")
         {
            newdf %>%
               group_by(Gender) %>%
               summarize(population = sum(Population), 
                         suicides = sum(Suicides_no), 
                         #find suicides per 100k population
                         suicides_per_100k = round((suicides / population) * 100000,2)) %>%
               plot_ly(labels = ~Gender, values = ~suicides_per_100k, type = 'pie') %>%       #plot the pie chart
               layout(title = paste("Suicide Proportion in",name),
                                     xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
                                     yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE))
         }
         
      })
      
   })
   
   ########################################### Code Ends for Continent Statistics#########################################################################################  
   
   ########################################### Code Starts for Countries #########################################################################################
   #line chart
   output$trendplot <- renderPlot({
     
      #filter dataframe based on slider input for years selected
     dummy_df<-suicide[suicide$Year >= input$slider2[1] & suicide$Year <= input$slider2[2],]
    
     #filter dataframe based on countries selected     
     dummy_df<-dummy_df[dummy_df$Country %in% input$variable,]
     
     #arrange the dataframe
     dummy_df %>%
        #group by Year and Country selected
       group_by(Year,Country) %>%
        #Find suicides per 100k population
       summarize(population = sum(Population), 
                 suicides = sum(Suicides_no), 
                 suicides_per_100k = (suicides / population) * 100000) %>%
        #plot the multi-line graph in ggplot
       ggplot(aes(Year,suicides_per_100k,color=Country,group=Country)) + 
       geom_line(size=1.5)+geom_point()+ggtitle("Suicide by Country")+
       xlab("Year")+ylab("Suicides per 100k population")+
       theme_bw(base_size = 18)
   })
   #display the data table
   output$table <- renderDataTable({
      
      #filter dataframe based on slider input for years selected
     dummy_df<-suicide[suicide$Year >= input$slider2[1] & suicide$Year <= input$slider2[2],]
     
     #filter dataframe based on countries selected   
     dummy_df<-dummy_df[dummy_df$Country %in% input$variable,]
     
     #arrange the dataframe
     dummy_df<-dummy_df %>%
        #group by Year and Country selected
       group_by(Year,Country) %>%
        #Find suicides per 100k population
       summarize(population = sum(Population), 
                 suicides = sum(Suicides_no), 
                 suicides_per_100k = (suicides / population) * 100000) 
     
     #sort the countries in dataframe alphabetically
     sort.df <- with(dummy_df,  dummy_df[order(dummy_df$Country) , ])
     
     
     #display the data table
     DT::datatable(sort.df[c("Year","Country","suicides_per_100k")], escape = FALSE, rownames = FALSE)
     
     
   })
   ########################################### Code Ends for Countries #########################################################################################  
   
}

# Run the application 
shinyApp(ui = ui, server = server)

