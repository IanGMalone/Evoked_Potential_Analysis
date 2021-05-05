library(tidyverse)

df_timebin1 <- read.csv(file = 'D:\\Neilsen\\Dataframes\\df_anova.csv')


df_timebin <- df_timebin1 %>%
  mutate(Group = as_factor(Group)) %>% 
  mutate(Time_Bin = as_factor(Time_Bin)) %>%
  mutate(Day = as_factor(Day))
  
df_d1 = df_timebin %>% 
  filter(Day == 1)


df_d4 = df_timebin %>% 
  filter(Day == 4)

anova_d1 <- aov(Scalar_Original_Value ~ Group + Time_Bin + Group:Time_Bin, data = df_d1)
summary(anova_d1)

TukeyHSD(anova_d1)



anova_d4 <- aov(Scalar_Original_Value ~ Group + Time_Bin + Group:Time_Bin, data = df_d4)
summary(anova_d4)

TukeyHSD(anova_d4)