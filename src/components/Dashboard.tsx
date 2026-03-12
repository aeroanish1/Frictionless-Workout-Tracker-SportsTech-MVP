import React, { useMemo } from 'react';
import { Workout } from '../types';
import { 
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer,
  PieChart, Pie, Cell, Legend
} from 'recharts';
import { format, parseISO, subDays } from 'date-fns';
import { TrendingUp, Dumbbell, Calendar } from 'lucide-react';

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

    return { totalWorkouts, totalVolume, volumeTrend, muscleData };
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
