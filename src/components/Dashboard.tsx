import React, { useMemo } from 'react';
import { Workout } from '../types';
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';
import { format, parseISO, subDays } from 'date-fns';
import { TrendingUp, Dumbbell, Calendar, Crown, Zap, Flame } from 'lucide-react';

interface DashboardProps {
  workouts: Workout[];
}

const COLORS = ['#000000', '#3f3f46', '#71717a', '#a1a1aa', '#d4d4d8'];

export const Dashboard: React.FC<DashboardProps> = ({ workouts }) => {
  const stats = useMemo(() => {
    if (workouts.length === 0) return null;

    const totalWorkouts = workouts.length;
    const totalVolume = workouts.reduce((acc, w) => 
      acc + w.exercises.reduce((exAcc, ex) => exAcc + (ex.sets * ex.reps * ex.weight), 0), 0
    );

    // Volume trend
    const volumeTrend = workouts.slice(0, 7).reverse().map(w => ({
      date: format(parseISO(w.date), 'MMM d'),
      volume: w.exercises.reduce((acc, ex) => acc + (ex.sets * ex.reps * ex.weight), 0)
    }));

    // Muscle group distribution
    const muscleGroups: Record<string, number> = {};
    workouts.forEach(w => {
      w.exercises.forEach(ex => {
        const mg = ex.muscleGroup || 'Other';
        muscleGroups[mg] = (muscleGroups[mg] || 0) + ex.sets;
      });
    });

    const muscleData = Object.entries(muscleGroups).map(([name, value]) => ({ name, value }));

    // PR Calculations
    let heaviestLift = { weight: 0, name: '', date: '' };
    let longestCardio = { duration: 0, name: '', date: '' };
    let maxVolumeSession = { volume: 0, date: '' };

    workouts.forEach(w => {
      let sessionVolume = 0;
      w.exercises.forEach(ex => {
        const vol = (ex.sets || 0) * (ex.reps || 0) * (ex.weight || 0);
        sessionVolume += vol;

        if (ex.weight && ex.weight > heaviestLift.weight) {
          heaviestLift = { weight: ex.weight, name: ex.name, date: w.date };
        }
        if (ex.duration && ex.duration > longestCardio.duration) {
          longestCardio = { duration: ex.duration, name: ex.name, date: w.date };
        }
      });
      if (sessionVolume > maxVolumeSession.volume) {
        maxVolumeSession = { volume: sessionVolume, date: w.date };
      }
    });

    const prs = { heaviestLift, longestCardio, maxVolumeSession };

    return { totalWorkouts, totalVolume, volumeTrend, muscleData, prs };
  }, [workouts]);

  if (!stats) {
    return (
      <div className="p-12 text-center bg-zinc-50 rounded-3xl border border-dashed border-zinc-300">
        <Dumbbell className="mx-auto text-zinc-300 mb-4" size={48} />
        <p className="text-zinc-500 font-medium">No data yet. Log your first workout to see insights.</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="p-6 bg-white rounded-3xl shadow-sm border border-black/5">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-zinc-100 rounded-xl">
              <Calendar size={20} className="text-zinc-600" />
            </div>
            <h3 className="font-semibold text-zinc-900">Total Workouts</h3>
          </div>
          <p className="text-4xl font-bold tracking-tight">{stats.totalWorkouts}</p>
        </div>

        <div className="p-6 bg-white rounded-3xl shadow-sm border border-black/5">
          <div className="flex items-center gap-3 mb-4">
            <div className="p-2 bg-zinc-100 rounded-xl">
              <TrendingUp size={20} className="text-zinc-600" />
            </div>
            <h3 className="font-semibold text-zinc-900">Total Volume</h3>
          </div>
          <p className="text-4xl font-bold tracking-tight">{stats.totalVolume.toLocaleString()} <span className="text-lg font-normal text-zinc-400">lbs</span></p>
        </div>
      </div>

      {/* PR Hall of Fame Section */}
      <div className="space-y-4">
        <h3 className="font-semibold text-zinc-900 px-1 flex items-center gap-2">
          <Crown size={20} className="text-amber-500" />
          PR Hall of Fame
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Heaviest Lift */}
          <div className="p-5 bg-gradient-to-br from-amber-50 to-orange-50 rounded-3xl border border-amber-100 shadow-sm relative overflow-hidden group">
            <div className="absolute -right-4 -bottom-4 opacity-10 group-hover:scale-110 transition-transform duration-500">
              <Dumbbell size={100} />
            </div>
            <div className="flex items-center gap-2 mb-2">
              <div className="p-1.5 bg-amber-100 rounded-lg text-amber-600">
                <Crown size={18} />
              </div>
              <span className="text-xs font-bold text-amber-700 tracking-wider uppercase">Heaviest Lift</span>
            </div>
            {stats.prs.heaviestLift.weight > 0 ? (
              <>
                <p className="text-2xl font-black text-amber-900 mt-2">{stats.prs.heaviestLift.weight} <span className="text-sm font-semibold">lbs</span></p>
                <p className="text-sm font-medium text-amber-700/80 truncate mt-1">{stats.prs.heaviestLift.name}</p>
                <p className="text-xs text-amber-600/60 mt-2">{format(parseISO(stats.prs.heaviestLift.date), 'MMM d, yyyy')}</p>
              </>
            ) : (
              <p className="text-sm text-amber-700/60 mt-4">No weights logged yet.</p>
            )}
          </div>

          {/* Longest Cardio */}
          <div className="p-5 bg-gradient-to-br from-blue-50 to-cyan-50 rounded-3xl border border-blue-100 shadow-sm relative overflow-hidden group">
            <div className="absolute -right-4 -bottom-4 opacity-10 group-hover:scale-110 transition-transform duration-500">
              <Zap size={100} />
            </div>
            <div className="flex items-center gap-2 mb-2">
              <div className="p-1.5 bg-blue-100 rounded-lg text-blue-600">
                <Zap size={18} />
              </div>
              <span className="text-xs font-bold text-blue-700 tracking-wider uppercase">Endurance King</span>
            </div>
            {stats.prs.longestCardio.duration > 0 ? (
              <>
                <p className="text-2xl font-black text-blue-900 mt-2">
                  {Math.floor(stats.prs.longestCardio.duration / 60)}<span className="text-sm font-semibold">m</span> {stats.prs.longestCardio.duration % 60}<span className="text-sm font-semibold">s</span>
                </p>
                <p className="text-sm font-medium text-blue-700/80 truncate mt-1">{stats.prs.longestCardio.name}</p>
                <p className="text-xs text-blue-600/60 mt-2">{format(parseISO(stats.prs.longestCardio.date), 'MMM d, yyyy')}</p>
              </>
            ) : (
              <p className="text-sm text-blue-700/60 mt-4">No cardio logged yet.</p>
            )}
          </div>

          {/* Volume Monster */}
          <div className="p-5 bg-gradient-to-br from-rose-50 to-pink-50 rounded-3xl border border-rose-100 shadow-sm relative overflow-hidden group">
            <div className="absolute -right-4 -bottom-4 opacity-10 group-hover:scale-110 transition-transform duration-500">
              <Flame size={100} />
            </div>
            <div className="flex items-center gap-2 mb-2">
              <div className="p-1.5 bg-rose-100 rounded-lg text-rose-600">
                <Flame size={18} />
              </div>
              <span className="text-xs font-bold text-rose-700 tracking-wider uppercase">Volume Monster</span>
            </div>
            {stats.prs.maxVolumeSession.volume > 0 ? (
              <>
                <p className="text-2xl font-black text-rose-900 mt-2">
                  {stats.prs.maxVolumeSession.volume.toLocaleString()} <span className="text-sm font-semibold">lbs</span>
                </p>
                <p className="text-sm font-medium text-rose-700/80 mt-1">Single session total</p>
                <p className="text-xs text-rose-600/60 mt-2">{format(parseISO(stats.prs.maxVolumeSession.date), 'MMM d, yyyy')}</p>
              </>
            ) : (
              <p className="text-sm text-rose-700/60 mt-4">No volume logged yet.</p>
            )}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="p-6 bg-white rounded-3xl shadow-sm border border-black/5">
          <h3 className="font-semibold text-zinc-900 mb-6">Volume Trend (Last 7)</h3>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={stats.volumeTrend}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                <XAxis dataKey="date" axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#a1a1aa' }} />
                <YAxis axisLine={false} tickLine={false} tick={{ fontSize: 12, fill: '#a1a1aa' }} />
                <Tooltip 
                  contentStyle={{ borderRadius: '16px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                />
                <Line 
                  type="monotone" 
                  dataKey="volume" 
                  stroke="#000" 
                  strokeWidth={3} 
                  dot={{ r: 4, fill: '#000', strokeWidth: 2, stroke: '#fff' }}
                  activeDot={{ r: 6, strokeWidth: 0 }}
                />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        <div className="p-6 bg-white rounded-3xl shadow-sm border border-black/5">
          <h3 className="font-semibold text-zinc-900 mb-6">Sets per Muscle Group</h3>
          <div className="h-[250px] w-full">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={stats.muscleData}
                  cx="50%"
                  cy="50%"
                  innerRadius={60}
                  outerRadius={80}
                  paddingAngle={5}
                  dataKey="value"
                >
                  {stats.muscleData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip 
                  contentStyle={{ borderRadius: '16px', border: 'none', boxShadow: '0 10px 15px -3px rgb(0 0 0 / 0.1)' }}
                />
                <Legend verticalAlign="bottom" height={36}/>
              </PieChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </div>
  );
};
