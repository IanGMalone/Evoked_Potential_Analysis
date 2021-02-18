library(lme4)
library(psycho)
library(tidyverse)

df_p2p_scaled <- read.csv(file = 'D:\\df_p2p_scaled.csv')


fit <- lmer(p2p_amplitude_scaled ~ Stim_Amplitude*Day_Stim + (Day_Stim|Group) + (1|Animal), data=df_p2p_scaled)
summary(fit)

results <- analyze(fit, CI = 95)

summary(results) %>% 
  mutate(p = psycho::format_p(p))

# random intercept ... lmer(y ~ x + (1|randomGroup), data = myData)
# random slope ... lmer(y ~ x + (randomSlope|randomGroup), data = myData)